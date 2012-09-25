class Slic3r

  def self.meta_dir
    File.join Rails.root, *%w(config slic3r)
  end

  def self.version_numbers
    files = Dir.entries(meta_dir).reject{ |f| File.directory?(f) }
    files.map { |f| /slic3r_([0-9x.]+)_defaults.ini/.match(f) }.compact.map {|m| m[1]}
  end

  def self.current_version
    @current_version ||= Slic3r.new(version_numbers.last) 
  end

  def initialize(version_number)
    @defaults_path = File.join self.class.meta_dir, "slic3r_#{version_number}_defaults.ini"
    @ui_layout_path = File.join self.class.meta_dir, "slic3r_#{version_number}_ui_layout.yml"
    @threads = Rails.env.development? ? 2 : 6
  end


  # Field Definitions
  # -------------------------------------------

  # The slic3r fields in a hierarchy of hashes denoting the layout of the fields in the ui
  def ui_layout
    return @ui_layout if defined? @ui_layout

    # Loading the layout
    ui_layout_yaml = YAML.load_file(@ui_layout_path)

    # Parses and formats a single field in the layout
    parse_field = Proc.new do |section, (param, meta_data)|
      # Convert the string meta data short hand to the hash map long hand notation
      section[param.to_sym] = meta_data.is_a?(String) ? {:type => meta_data} : meta_data.symbolize_keys
      section[param.to_sym][:title] = param.gsub("_", " ").titleize unless section[param.to_sym].include? :title
      section
    end

    # Parses a single category in the layout and recursively formats it
    parse_category = Proc.new do |category, (title, content)|
      # Identifying sub categorys and field elements
      fields, sub_categories = fields_and_sub_categories(content)
      # Parsing the sub categories and fields
      category[title] = fields.inject({}, &parse_field).merge sub_categories.inject({}, &parse_category)
      category
    end

    # Recursively formatting the layout for easy use
    @ui_layout = ui_layout_yaml.inject({}, &parse_category)
  end

  def safe_ui_layout
    return @safe_ui_layout if defined? @safe_ui_layout

    reject_unsafe = Proc.new do |category, (title, content)|
      fields, sub_categories = fields_and_sub_categories(content)
      category[title] = (fields.reject {|k,v| v[:unsafe]}).merge( sub_categories.inject({}, &reject_unsafe).reject {|k,v| v.blank?} )
      category
    end

    @safe_ui_layout = ui_layout.inject({}, &reject_unsafe)
  end

  # The slic3r fields flattened as a single hash
  def fields
    unless defined? @fields
      flatten = Proc.new do |hash, (title, content)|
        fields, sub_categories = fields_and_sub_categories(content)
        hash.merge fields.merge( sub_categories.inject({}, &flatten) )
      end

      @fields = ui_layout.inject({}, &flatten)
    end
    @fields
  end

  def safe_fields(virtual_attribute_names = false)
    safe_fields = fields.reject{|k,v| v[:unsafe]}
    return safe_fields unless virtual_attribute_names

    # Generates the active record virtual attribute names
    virtual_attributes = safe_fields.map do |k,v|
      if v[:type] == "coordinate"
        [:"#{k}_0_config_row", :"#{k}_1_config_row"]
      else
        :"#{k}_config_row"
      end
    end
    return virtual_attributes.flatten
  end

  def commonly_used_fields
    @basic_fields if defined? @basic_fields
    basic_field_syms = [:fill_density, :layer_height, :support_material, :filament_diameter, :temperature, :first_layer_temperature, :cooling]
    @basic_fields = fields.select{|k,v| basic_field_syms.include? k}
    @basic_fields[:filament_diameter][:title] = "Filament Diameter"
    @basic_fields
  end


  # Loading and Saving
  # -------------------------------------------

  def default_config_file
    File.new @defaults_path
  end

  def load(path = @defaults_path)
    ini_lines = IO.readlines(path).reject{|line| line.starts_with? "#"}
    # Parsing the lines into a hash of strings
    config_data = Hash[ini_lines.map {|line| line.split("=").map(&:strip) }].symbolize_keys

    # Converting the strings to the correct data types based on the slic3r field definitions
    config_data.inject({}) do |hash, (k, v)|
      hash[k.to_sym] = case (type = fields[k].present? ? fields[k][:type] : "string")
        when "double" then v.to_f
        when "int" then v.to_i
        when "coordinate" then v.split(fields[k][:join_char] || ",").map &:to_i
        when "bool" then ["true","1", "t", "on"].include?(v.downcase)
        else v.gsub("\\n", "\n")
      end
      if type == "coordinate"
        [0,1].each {|i| hash[:"#{k}_#{i}"] = hash[k.to_sym][i] }
        hash.delete(k.to_sym)
      end
      hash
    end
  end

  def unsafe_defaults
    @unsafe_default ||= load().select{|k,v| fields.include?(k) and fields[k][:unsafe]}
  end

  def serialize(configs)
    # Excluding unsafe configs
    safe_configs = configs.select{|k,v| safe_fields.include? k and safe_fields[k][:serialize] != false }
    # Serializing coordinate _0 and _1 values to single arrays
    safe_fields.select{|k,v| v[:type] == "coordinate"}.each do |k,v|
      safe_configs[k] = [0,1].map {|i| configs[:"#{k}_#{i}"] || 0 }
    end
    # Loading unsafe configs from the slic3r defaults
    serialized_configs = unsafe_defaults.merge(safe_configs).map do |k,v|
      # Serializing everything
      serialized_v = case (fields[k].present? ? fields[k][:type] : "string")
        when 'int' then v.to_i
        when 'bool' then v ? 1 : 0#'on' : 'off'
        when 'coordinate'
          (v.is_a?(Array) and v.length == 2 ? v.map(&:to_i) : [0,0]).join(fields[k][:join_char] || ",")
        else
          v.is_a?(Array) ? v.join(",") : v
        end
      "#{k} = #{serialized_v.to_s.gsub("\n", "\\n")}"
    end

    serialized_configs.join("\n")
  end


  # Slicing
  # -------------------------------------------

  # Runs slic3r on the cad model
  def slice(cad_file_path, config_file_path, validating_gcode_profile = false)
    puts "Slicing.."
    g_code_path = "/home/sliceruser/#{UUIDTools::UUID.random_create.to_s}.gcode"
    FileUtils.rm(g_code_path) if File.exists? g_code_path
    output = {}

    # Compile the slic3r command
    slic3r = File.join Rails.root, "script", "slicer.sh"
    cmd = "sudo #{slic3r} --load \"#{config_file_path}\" -o \"#{g_code_path}\" -j #{@threads} \"#{cad_file_path}\""
    output[:cmd] = cmd if validating_gcode_profile == true # For debugging

    # Run the slic3r command
    puts "\n\n\n" + cmd + "\n\n"
    stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
    output[:std_io] = {:stdout => stdout.read, :stderr => stderr.read}

    #raise IO.read(config_file_path)
    #raise output.inspect

    # TODO: delete the test file somehow (we don't have the correct priveledges)
    # File.unlink(g_code_path) if validating_gcode_profile

    if File.exists?(g_code_path) and output[:std_io][:stderr].blank?
      output[:file] = File.new(g_code_path)
      output[:status] = :ready_to_print
    else
      output[:status] = :error
    end

    if output[:status] == :ready_to_print
      puts "Slicing.. [ #{"DONE".green} ]"
    elsif output[:status] == :error
      puts "Slicing.. [ #{"ERROR".red} ]"
    end
    return output
  end

  def parseErrors(std_err)
    errors = {}
    std_err.split("\n").each do |error_line|
      row_name_match = error_line.match(/--([a-zA-Z\-]+)/)
      if row_name_match.present?
        errors[:"#{row_name_match[1].gsub("-", "_")}_config_row"]= error_line
      else
        errors[:base] ||= []
        errors[:base] << error_line
      end
    end
    return errors
  end

  private

    # fields, sub_categories = fields_and_sub_categories(some_ui_layout_hash)
    def fields_and_sub_categories(content)
      # Identifying sub categorys and field elements
      [content.select { |param, meta_data| field_meta_data?(meta_data) },
      content.reject { |param, meta_data| field_meta_data?(meta_data) }]
    end

    def field_meta_data?(meta_data) # used in parsing the ui layout and safe ui layout
      return true if meta_data.is_a?(String)
      meta_data.select{|k,v| field_attributes.include?(k.to_sym) == false }.length == 0
    end

    def field_attributes
      %w(type title units options unsafe serialize join_char).map &:to_sym
    end
end
require File.join Rails.root, "app", "uploaders", "slic3r_profile_uploader.rb"
require File.join Rails.root, "app", "models", "slic3r.rb"

class GCodeProfile < ActiveRecord::Base

  belongs_to :print_queue
  belongs_to :config_file

  has_many :print_jobs

  store :config
  attr_accessor :config_file_uploader
  mount_uploader :config_file_uploader, Slic3rProfileUploader

  def config_file_uploader_will_change!
    config_file_uploader.load_configs
  end
  def config_file_uploader_changed?
    false
  end

  def self.slic3r
    Slic3r.current_version
  end

  def slic3r
    Slic3r.current_version
  end

  # Defining Prefixed config store methods
  slic3r.safe_fields(true).each do |row|
    define_method(:"#{row}=") do |value|
      self.config_will_change!
      self.config.merge! row.to_s.sub(/(.*)_config_row/, '\1').to_sym => value
    end
    define_method(row) do
      self.config[row.to_s.sub(/(.*)_config_row/, '\1').to_sym]
    end
  end

  attr_accessible :name, :glob, :remote_config_file_url, :config_file_uploader, *(slic3r.safe_fields true)

  validates_uniqueness_of :name, :scope => :print_queue_id, :message => "^A profile with this name already exists"
  validates_uniqueness_of :glob, :scope => :print_queue_id, :message => "^A profile with the same url already exists"
  validates :name, :presence => true, :length => { :in => 1..35 }

  # Validating the configuration
  validate do
    if config_changed?
      update_config_file if config_file_dirty?
      # We run a test slic3r run to determine if their are any validation issues with the config file
      f = config_file.file.to_file
      test = slic3r.slice "/home/sliceruser/cube.stl", f.path, true

      slic3r.parseErrors(test[:std_io][:stderr]).each { |k,v| errors[k] = v }
    end
  end

  before_validation :on => :create do
    # Default to slic3r defaults for the config file
    self.config = slic3r.load if self.config.blank?
  end

  before_save do
    self.glob = name.urlize
  end

  def config= c
    write_attribute :config, c
    @config_file_dirty_flag = true
  end

  def config_file
    update_config_file if config_file_dirty?
    ConfigFile.find(read_attribute :config_file_id)
  end

  def config_file_dirty?
    !defined?(@config_file_dirty_flag) or @config_file_dirty_flag
  end

  def update_config_file
    @config_file_dirty_flag = false
    f = Tempfile.new(['slic3r_config_tmp_file','.ini'])
    begin
      f.write slic3r.serialize(config)
      @config_temp_file = f
      f.close(false)
      #raise IO.read f # for debugging
      self.config_file = ConfigFile.find_or_create_by_file f
      print_jobs.each &:file_changed
    ensure
      f.unlink
    end
  end

  def glob
    name.urlize
  end

  def to_s
    name
  end

end
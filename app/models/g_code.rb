require "fileutils"

class GCode < ActiveRecord::Base

  belongs_to :cad_file
  belongs_to :config_file

  def g_code_profiles
    config_file.g_code_profiles
  end
  
  def print_jobs
    cad_file.print_jobs
  end

  attr_accessible :cad_file_id, :config_file_id
  validates_uniqueness_of :cad_file_id, :scope => :config_file_id


  # File Upload
  # -------------------------------------------------

  class GCodeFileUploader < CarrierWave::Uploader::Base
    def extension_white_list
      %w(gcode ngc)
    end
  end

  mount_uploader :file, GCodeFileUploader

  # GCode Generator Definitions
  # -------------------------------------------------

  def self.types_by_ext
    #return @ext_map if defined? @ext_map
    @ext_map = { %w(stl obj amf) => "Slic3rGCode", %w(ngc gcode) => "GCode" }
    # Splitting the hash up so that it is in the format ext => class (for example: "ngc" => "GCode")
    @ext_map = @ext_map.inject({}) { |h, (k, v)| k.each { |ext| h[ext] = v }; h }
  end

  def self.file_exts
    types_by_ext.keys
  end


  # Resqueue Task
  # -------------------------------------------------

  before_create do
    # We set the type here so that when resque loads 
    # the task it will execute using the approrpiate
    # gcode generator
    self.type = GCode.types_by_ext[ cad_file.ext_name ]
    self.status ||= ( self.type == "GCode" ? :ready_to_print : :processing )
  end

  after_commit(:on => :create) do
    puts "moocows\n"*5
    puts "Resqueing!!!\n"*20
    puts self.type
    puts id.to_s
    Resque::Job.create(self.type.tableize, Kernel.const_get(self.type), id.to_s)
    puts "---\n"*10
    puts "Resque [DONE]\n"*20
  end


  # Status
  # -------------------------------------------------

  before_save do
    # if the status changes, update all the attached print jobs
    if status_changed?
      puts "#{status}\n"*10
      print_jobs.each { |job| job.update_attributes :status => self.status }
    end
  end

end
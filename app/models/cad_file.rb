class CadFile < ActiveRecord::Base
  class CadFileUploader < CarrierWave::Uploader::Base

    def store_dir
      if Rails.configuration.enable_s3
        "#{model.class.to_s.underscore}/#{model.id}"
      else
        "/home/sliceruser/slic3r_jobs/#{model.class.to_s.underscore}/#{model.id}"
      end
    end

    def cache_dir
      "/home/sliceruser/slic3r_jobs/#{model.class.to_s.underscore}/#{model.id}/cache"
    end

    def extension_white_list
      GCode.file_exts
    end

    def extract_extname
      model.ext_name = File.extname( self.filename() ).delete(".").downcase()
    end

    process :extract_extname

    def generate_hash
      model.hash = model.class.generate_hash File.new(current_path)
    end
  end

  def self.find_or_create_by_file(f)
    f_path = f.tempfile.path if f.is_a?(ActionDispatch::Http::UploadedFile)
    f_path = f.path if f.is_a?(File) or f.is_a?(Tempfile)

    self.find_or_create_by_file_hash( self.generate_hash(f_path), :file => f )
  end

  def self.generate_hash(f)
    Digest::SHA512.file(f).base64digest
  end

  attr_accessible :file, :remote_file_url, :file_hash
  mount_uploader :file, CadFileUploader

  has_many :g_codes, :dependent => :destroy
  has_many :print_jobs, :dependent => :destroy
end
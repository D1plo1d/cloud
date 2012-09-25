class Slic3rProfileUploader < CarrierWave::Uploader::Base
  storage :file # These files are only used in the upload process so we never save them to s3

  def extension_white_list
    %w(ini)
  end

  def load_configs
    # Saving the configs to the model
    model.config = Slic3r.load(current_path)
  end

end
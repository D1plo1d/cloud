if Rails.configuration.enable_s3
  bucket = "#{Rails.env.to_s.downcase}.cloudslicing"

  CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_credentials = {
      :provider               => ENV['S3_BUCKET_NAME'],                            # required
      :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],                         # required
      :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],                     # required
      :region                 => 'us-east-1'                                       # optional, defaults to 'us-east-1'
    }
    config.fog_directory  = bucket                                                 # required
    config.fog_public     = false                                                  # optional, defaults to true
    #config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}                # optional, defaults to {}
  end
end


# Extending Carrierwave
class CarrierWave::Uploader::Base
  def to_file
    # TODO: this method for each version of a file
    # TODO: if the cache is not local then download it and return a temp file
    cache_stored_file! unless cached? or file.respond_to? :to_file
    return file.to_file
  end
end
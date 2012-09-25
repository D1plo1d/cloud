# TODO: private pub needs to load it's stuff from env variables or switch to pusher
#config_data = YAML.load ERB.new File.read File.join(Rails.root, "config",  "private_pub.yml")
PrivatePub.load_config config_data, Rails.env

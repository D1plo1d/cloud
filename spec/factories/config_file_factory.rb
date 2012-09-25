FactoryGirl.define do

  factory :config_file do
    file File.open(File.join Rails.root, "spec", "fixtures", "config.ini")
  end

end
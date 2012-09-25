FactoryGirl.define do

  factory :g_code do
    association :cad_file
    association :config_file

    initialize_with { GCode.find_or_create_by_cad_file_and_config_file(cad_file, config_file)}
  end

end
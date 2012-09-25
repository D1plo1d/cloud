FactoryGirl.define do
  factory :g_code_profile do
    sequence(:name) {|n| "profile ##{GCodeProfile.count}" }

    association :print_queue, :factory => :empty_print_queue
    association :config_file
  end
end
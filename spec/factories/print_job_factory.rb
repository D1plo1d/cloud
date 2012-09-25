FactoryGirl.define do

  factory :print_job do
    association :cad_file
    association :g_code_profile
    before_create do |job|
      job.print_queue_id = job.g_code_profile.print_queue_id
    end
  end

end
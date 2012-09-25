FactoryGirl.define do

  factory :empty_print_queue, :class => PrintQueue do
    association :owner, :factory => :user
    sequence(:name) {|n| "Ultimaker ##{PrintQueue.count}" }

    factory :print_queue do
      after_create do |queue|
        FactoryGirl.create_list(:print_job, 7, :print_queue => queue)
        #FactoryGirl.create_list(:printer, 1, :print_queue => queue)
        FactoryGirl.create_list(:g_code_profile, 4, :print_queue => queue)

        user = FactoryGirl.create(:user)
        user.add_role :user, queue
        user.save!
      end
    end

  end

end
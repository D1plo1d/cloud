FactoryGirl.define do
  factory :user do
    sequence(:username) {|n| "username#{User.count}" }
    sequence(:email) {|n| "test#{User.count}@test.com" }
    password "hunter2"
    password_confirmation "hunter2"


    trait :with_queues do
      after_create do |user|
        FactoryGirl.create_list(:print_queue, 2, :owner => user)
      end
    end

    trait :confirmed do
      confirmed_at Time.now
    end

  end
end
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z" }
    confirmed_at { 1.day.ago }
    name { "A name is now required" }
    role { "normal" }
  end

  factory :admin_user, parent: :user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    role { "admin" }
  end

  factory :invited_user, parent: :user do
    invitation_sent_at { 1.minute.ago }
    invitation_accepted_at { nil }
  end

  factory :active_user, parent: :invited_user do
    invitation_accepted_at { Time.current }
  end

  factory :suspended_user, parent: :user do
    suspended_at { Time.current }
    reason_for_suspension { "Testing" }
  end

  factory :locked_user, parent: :user do
    locked_at { Time.current }
  end
end

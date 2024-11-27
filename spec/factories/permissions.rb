FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| "Permission ##{n}" }
    oauth_application
  end
end

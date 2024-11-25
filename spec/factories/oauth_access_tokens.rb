FactoryBot.define do
  factory :oauth_access_token do
    sequence(:resource_owner_id) { |n| n }
    application { association :oauth_application }
    expires_in { 2.hours }
  end
end

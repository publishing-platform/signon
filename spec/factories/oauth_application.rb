FactoryBot.define do
  factory :oauth_application do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
    home_uri { "https://app.com/" }
    description { "Important information about this app" }
  end
end
FactoryBot.define do
  factory :oauth_application do
    transient do
      with_permissions { [] }
    end

    sequence(:name) { |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
    home_uri { "https://app.com/" }
    description { "Important information about this app" }

    after(:create) do |app, evaluator|
      evaluator.with_permissions.each do |permission_name|
        next if permission_name == Permission::SIGNIN_NAME

        create(:permission, oauth_application: app, name: permission_name)
      end
    end
  end
end

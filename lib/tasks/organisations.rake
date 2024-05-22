namespace :organisations do
  desc "Fetch organisations"
  task fetch: :environment do
    Services::OrganisationFetcher.call
  end
end

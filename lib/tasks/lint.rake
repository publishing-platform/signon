desc "Run all linters"
task lint: :environment do
  sh "bundle exec rubocop"
  sh "bundle exec brakeman . --except CheckRenderInline --quiet"
  sh "yarn run lint"
end

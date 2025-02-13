module Services
  class OrganisationFetcher < ApplicationService
    def call
      organisations.each do |organisation_data|
        update_or_create_organisation(organisation_data)
      end
    end

  private

    def organisations
      @organisations ||= PublishingPlatformApi.organisations.organisations.with_subsequent_pages
    end

    def update_or_create_organisation(organisation_data)
      content_id = organisation_data["details"]["content_id"]
      slug = organisation_data["details"]["slug"]

      organisation = Organisation.find_by(content_id:) ||
        Organisation.find_by(slug:) ||
        Organisation.new(content_id:)

      update_data = {
        content_id:,
        slug:,
        name: organisation_data["title"],
        organisation_type: organisation_data["format"],
        abbreviation: organisation_data["details"]["abbreviation"],
        closed: organisation_data["details"]["status"] == "closed",
      }

      organisation.update!(update_data)
    end
  end
end

module Services
  class OrganisationFetcher < ApplicationService
    def call
      organisations.each do |organisation_data|
        update_or_create_organisation(organisation_data)
      end
    end

  private

    def organisations
      # call API here to fetch organisations
      [
        {
          title: "Research and Development",
          format: "Department",
          details: {
            slug: "research-and-development",
            abbreviation: nil,
            status: "live",
            content_id: "96ae61d6-c2a1-48cb-8e67-da9d105ae381",
          },
        },
        {
          title: "Digital Services",
          format: "Department",
          details: {
            slug: "digital-services",
            abbreviation: "DS",
            status: "live",
            content_id: "af07d5a5-df63-4ddc-9383-6a666845ebe9",
          },
        },
        {
          title: "Financial Services",
          format: "Department",
          details: {
            slug: "financial-services",
            abbreviation: "FS",
            status: "live",
            content_id: "06056197-bc69-4147-aa28-070bca132178",
          },
        },
      ]
    end

    def update_or_create_organisation(organisation_data)
      content_id = organisation_data[:details][:content_id]
      slug = organisation_data[:details][:slug]

      organisation = Organisation.find_by(content_id:) ||
        Organisation.find_by(slug:) ||
        Organisation.new(content_id:)

      update_data = {
        content_id:,
        slug:,
        name: organisation_data[:title],
        organisation_type: organisation_data[:format],
        abbreviation: organisation_data[:details][:abbreviation],
        closed: organisation_data[:details][:devgovuk_status] == "closed",
      }

      organisation.update!(update_data)
    end
  end
end

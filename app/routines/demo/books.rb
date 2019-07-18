# Imports a book from CNX and creates a course with periods from its data
class Demo::Books < Demo::Base
  lev_routine

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :import_book
  uses_routine AddEcosystemToCourse, as: :add_ecosystem_to_course

  protected

  def exec(config:, version: :defined)
    configuration = OpenStax::Exercises::V1.configuration

    raise(
      'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET' +
      ' env vars and then restart any background job workers to use Demo::Books'
    ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)

    book_config = config.is_a?(Demo::Config::Book) ? config : Demo::Config::Book.new(config)

    book_id = book_config.book_id(version)

    log { "Importing #{book_config.salesforce_book_name} from #{book_config.archive_url}" }


    ecosystem = OpenStax::Exercises::V1.use_real_client do
      run(
        :import_book,
        book_cnx_id: book_id,
        archive_url: book_config.archive_url_base,
        reading_processing_instructions: book_config.reading_processing_instructions
      ).outputs.ecosystem
    end

    @retries = 0
    create_or_update_catalog_offering(book_config, ecosystem)

    log { "#{book_config.salesforce_book_name} book import complete" }
  end

  def create_or_update_catalog_offering(book_config, ecosystem)
    # We can run into an issue where 2 offerings try to grab the same number
    # Create a sub-transaction and retry if that happens
    Catalog::Models::Offering.transaction(requires_new: true) do
      offering = find_catalog_offering_by_salesforce_book_name book_config.salesforce_book_name

      if offering.nil?
        # Create the catalog offering
        Catalog::CreateOffering[
          salesforce_book_name: book_config.salesforce_book_name,
          appearance_code: book_config.appearance_code,
          title: book_config.default_course_name,
          description: book_config.default_course_name,
          webview_url: book_config.webview_url,
          pdf_url: book_config.pdf_url,
          is_tutor: book_config.is_tutor,
          is_concept_coach: book_config.is_concept_coach,
          is_available: true,
          content_ecosystem_id: ecosystem.id
        ]
      else
        # Update the catalog offering and existing courses
        offering.to_model.update_attribute :ecosystem, ecosystem.to_model
        offering.to_model.courses.each do |course|
          run(:add_ecosystem_to_course, course: course, ecosystem: ecosystem)
        end
      end
    end
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    @retries += 1
    retry if @retries < 3
  end
end

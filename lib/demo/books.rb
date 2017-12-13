require_relative 'base'
require_relative 'config/book'

# Imports a book from CNX and creates a course with periods from it's data
class Demo::Books < Demo::Base
  lev_routine

  disable_automatic_lev_transactions

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :import_book
  uses_routine AddEcosystemToCourse, as: :add_ecosystem_to_course

  protected

  def exec(config: :all, version: :defined)
    OpenStax::Exercises::V1.use_real_client
    configuration = OpenStax::Exercises::V1.configuration

    fatal_error(code: 'missing_openstax_exercises_tokens',
                message: 'Please set the environment variables OPENSTAX_EXERCISES_CLIENT_ID ' +
                         'and OPENSTAX_EXERCISES_SECRET to use demo:book') \
      if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)

    # Parallel step
    in_parallel(Demo::Config::Book[config], transaction: true) do |book_configs, idx_start|
      book_configs.each do |book_config|
        book_id = book_config.book_id(version)

        log { "Importing #{book_config.salesforce_book_name} from #{book_config.archive_url}" }

        ecosystem = run(
          :import_book,
          book_cnx_id: book_id,
          archive_url: book_config.archive_url_base,
          reading_processing_instructions: book_config.reading_processing_instructions
        ).outputs.ecosystem

        create_or_update_catalog_offering(book_config, ecosystem)

        log { "#{book_config.salesforce_book_name} book import complete" }
      end # book
    end # process

    wait_for_parallel_completion
  end

  def create_or_update_catalog_offering(book_config, ecosystem)
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
end

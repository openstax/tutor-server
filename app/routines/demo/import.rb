# Imports a demo book from CNX
class Demo::Import < Demo::Base
  MAX_RETRIES = 3

  lev_routine transaction: :read_committed, use_jobba: true

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :import_ecosystem
  uses_routine AddEcosystemToCourse, as: :add_ecosystem_to_course

  protected

  def exec(import:)
    configuration = OpenStax::Exercises::V1.configuration

    raise(
      'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET' +
      ' env vars and then restart any background job workers to use Demo::Books'
    ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)

    book = import[:book]
    catalog_offering = import[:catalog_offering]

    book[:archive_url_base] ||= Rails.application.secrets.openstax[:cnx][:archive_url]

    book[:uuid], book[:version] = book[:uuid].split('@', 2) if book[:version].blank?

    if book[:version] == 'latest'
      book[:uuid] = book[:uuid].split('@', 2).first
      book.delete :version
    end

    book_cnx_id = book[:version].blank? ? book[:uuid] : "#{book[:uuid]}@#{book[:version]}"

    log do
      "Importing #{catalog_offering[:title]} from #{book[:archive_url_base]}#{book_cnx_id}"
    end

    ecosystem_model = OpenStax::Exercises::V1.use_real_client do
      run(
        :import_ecosystem,
        book_cnx_id: book_cnx_id,
        archive_url: book[:archive_url_base],
        reading_processing_instructions: book[:reading_processing_instructions]
      ).outputs.ecosystem
    end

    attrs = catalog_offering.slice(
      :title,
      :description,
      :appearance_code,
      :salesforce_book_name,
      :default_course_name,
      :webview_url_base,
      :pdf_url_base
    ).merge(
      is_tutor: true,
      is_concept_coach: false,
      is_preview_available: true,
      is_available: true,
      ecosystem: ecosystem_model
    )

    # Retries could be replaced with UPSERTing the catalog offering
    @retries = 0
    outputs.catalog_offering = begin
      Catalog::Models::Offering.transaction(requires_new: true) do
        attrs[:title] ||= attrs[:salesforce_book_name] ||
                          attrs[:appearance_code].split('_').map(&:capitalize).join(' ')
        offering = Catalog::Models::Offering.find_by title: attrs[:title]

        if offering.nil?
          attrs[:salesforce_book_name] ||= attrs[:title]
          attrs[:default_course_name] ||= attrs[:title]
          attrs[:description] ||= attrs[:default_course_name]
          attrs[:webview_url_base] ||= book[:archive_url_base].sub('archive.', '')
          attrs[:webview_url] = "#{attrs.delete(:webview_url_base)}#{book_cnx_id}"
          attrs[:pdf_url_base] ||= book[:archive_url_base].sub('/contents/', '/exports/')
          attrs[:pdf_url] = "#{attrs.delete(:pdf_url_base)}#{book_cnx_id}"
          if @retries > 0
            attrs[:number] = (Catalog::Models::Offering.maximum(:number) || 0) + @retries + 1
          end

          # Create the catalog offering
          Catalog::CreateOffering[attrs]
        else
          attrs[:webview_url] = "#{attrs.delete(:webview_url_base)}#{book_cnx_id}" \
            unless attrs[:webview_url_base].blank?
          attrs[:pdf_url] = "#{attrs.delete(:pdf_url_base)}#{book_cnx_id}" \
            unless attrs[:pdf_url_base].blank?

          # Update the catalog offering and existing courses
          offering.update_attributes attrs
          offering.courses.each do |course|
            run(:add_ecosystem_to_course, course: course, ecosystem: ecosystem_model)
          end

          offering
        end
      end
    rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
      raise if @retries >= MAX_RETRIES

      @retries += 1

      retry
    end

    log_status outputs.catalog_offering.title
  end
end

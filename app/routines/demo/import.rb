# Imports a demo book from CNX
class Demo::Import < Demo::Base
  lev_routine

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :import_book
  uses_routine AddEcosystemToCourse, as: :add_ecosystem_to_course

  protected

  def exec(import:)
    configuration = OpenStax::Exercises::V1.configuration

    raise(
      'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET' +
      ' env vars and then restart any background job workers to use Demo::Books'
    ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)

    import[:archive_url_base] ||= Rails.application.secrets.openstax[:cnx][:archive_url]

    import[:cnx_book_id], import[:cnx_book_version] = import[:cnx_book_id].split('@', 2) \
      if import[:cnx_book_version].blank?

    if import[:cnx_book_version] == 'latest'
      import[:cnx_book_id] = import[:cnx_book_id].split('@', 2).first
      import.delete :cnx_book_version
    end

    book_cnx_id = import[:cnx_book_version].blank? ?
      import[:cnx_book_id] : "#{import[:cnx_book_id]}@#{import[:cnx_book_version]}"

    log { "Importing #{import[:title]} from #{import[:archive_url_base]}#{book_cnx_id}" }

    ecosystem = OpenStax::Exercises::V1.use_real_client do
      run(
        :import_book,
        book_cnx_id: book_cnx_id,
        archive_url: import[:archive_url_base],
        reading_processing_instructions: import[:reading_processing_instructions]
      ).outputs.ecosystem
    end

    attrs = import.slice(
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
      is_available: true,
      content_ecosystem_id: ecosystem.id
    )

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
          attrs[:webview_url_base] ||= import[:archive_url_base].sub('archive.', '')
          attrs[:webview_url] = "#{attrs.delete(:webview_url_base)}#{book_cnx_id}"
          attrs[:pdf_url_base] ||= import[:archive_url_base].sub('/contents/', '/exports/')
          attrs[:pdf_url] = "#{attrs.delete(:pdf_url_base)}#{book_cnx_id}"

          # Create the catalog offering
          Catalog::CreateOffering[attrs].to_model
        else
          attrs[:webview_url] = "#{attrs.delete(:webview_url_base)}#{book_cnx_id}" \
            unless attrs[:webview_url_base].blank?
          attrs[:pdf_url] = "#{attrs.delete(:pdf_url_base)}#{book_cnx_id}" \
            unless attrs[:pdf_url_base].blank?

          # Update the catalog offering and existing courses
          offering.update_attributes attrs
          offering.courses.each do |course|
            run(:add_ecosystem_to_course, course: course, ecosystem: ecosystem)
          end

          offering
        end
      end
    rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
      @retries += 1
      retry if @retries < 3
    end

    log_status outputs.catalog_offering.title
  end
end

# Imports a demo book from CNX
class Demo::Import < Demo::Base
  MAX_RETRIES = 3

  lev_routine transaction: :read_committed, use_jobba: true

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :import_ecosystem
  uses_routine AddEcosystemToCourse, as: :add_ecosystem_to_course

  protected

  def s3
    @s3 ||= OpenStax::Content::S3.new
  end

  def exec(import:)
    configuration = OpenStax::Exercises::V1.configuration

    book = import[:book]
    catalog_offering = import[:catalog_offering]

    if book[:run].blank?
      raise(
        'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET' +
        ' env vars and then restart any background job workers to use Demo::Books'
      ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)

      book[:archive_version] ||= s3.ls.last

      book[:version] ||= s3.ls(book[:archive_version]).map do |book_id|
        book_id.split('@')
      end.select { |uuid, version| uuid == book[:uuid] }.map { |uuid, version| version.to_f }.max

      log do
        "Importing #{catalog_offering[:title]} (#{book[:uuid]
        }@#{book[:version]}) from code version #{book[:archive_version]}"
      end

      if book[:reading_processing_instructions].blank?
        reading_processing_instructions_by_style = YAML.load_file(
          'config/reading_processing_instructions.yml'
        )
        book[:reading_processing_instructions] = \
          reading_processing_instructions_by_style[book[:style]]
      end

      ecosystem_model = OpenStax::Exercises::V1.use_real_client do
        run(
          :import_ecosystem,
          book.slice(:archive_version, :reading_processing_instructions, :comments).merge(
            book_uuid: book[:uuid], book_version: book[:version]
          )
        ).outputs.ecosystem
      end
    else
      ecosystem_model = eval book[:run]
    end

    attrs = catalog_offering.slice(
      :title,
      :description,
      :appearance_code,
      :salesforce_book_name,
      :default_course_name
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
        offering = Catalog::Models::Offering.without_deleted.find_by title: attrs[:title]

        if offering.nil?
          attrs[:salesforce_book_name] ||= attrs[:title]
          attrs[:default_course_name] ||= attrs[:title]
          attrs[:description] ||= attrs[:default_course_name]
          if @retries > 0
            attrs[:number] = (Catalog::Models::Offering.maximum(:number) || 0) + @retries + 1
          end

          # Create the catalog offering
          Catalog::CreateOffering[attrs]
        else
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

class ExportExerciseExclusions
  owncloud_secrets = Rails.application.secrets['owncloud']
  EE_STATS_FOLDER = owncloud_secrets['excluded_exercises_stats_folder']
  WEBDAV_BASE_URL = "#{owncloud_secrets['base_url']}/remote.php/webdav/#{EE_STATS_FOLDER}"

  lev_routine

  protected

  def exec(upload_by_course_to_owncloud: false, upload_by_exercise_to_owncloud: false)
    if upload_by_course_to_owncloud || upload_by_exercise_to_owncloud
      if upload_by_course_to_owncloud
        generate_by_course_csv
        upload_by_course_csv
      end

      if upload_by_exercise_to_owncloud
        generate_by_exercise_csv
        upload_by_exercise_csv
      end
    else
      outputs[:by_course] = exercises_by_course
      outputs[:by_exercise] = exercises_by_exercise
    end
  ensure
    remove_exported_files
  end

  def excluded_exercises
    @excluded_exercises ||= CourseContent::Models::ExcludedExercise.preload(
                              course: { teachers: { role: { role_user: :profile } } }
                            ).sort_by(&:exercise_number)
  end

  def exercises_by_ecosystems_and_pages
    @exercises_by_ecosystems_and_pages ||= {}.tap do |hash|
      excluded_exercises = Content::Models::Exercise.where(number: all_excluded_exercise_numbers)
                                                    .preload(page: :ecosystem)

      excluded_exercises.each do |excluded_exercise|
        page = excluded_exercise.page
        ecosystem = page.ecosystem

        hash[ecosystem] ||= {}
        hash[ecosystem][page] ||= []
        hash[ecosystem][page] << excluded_exercise
      end
    end
  end

  def all_excluded_exercise_numbers
    @excluded_exercise_numbers ||= excluded_exercises.map(&:exercise_number).uniq
  end

  def page_urls_by_pages
    @page_urls_by_pages ||= {}.tap do |hash|
      exercises_by_ecosystems_and_pages.each do |ecosystem, exercises_by_pages|
        exercises_by_pages.each do |page, exercises|
          hash[page] = OpenStax::Cnx::V1.webview_url_for(page.uuid)
        end
      end
    end
  end

  def exercise_urls_by_exercise_numbers
    @exercise_urls_by_exercise_numbers ||= {}.tap do |hash|
      all_excluded_exercise_numbers.each do |number|
        hash[number] = OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
      end
    end
  end

  def pages_by_ecosystems_and_exercise_numbers
    @pages_by_ecosystems_and_exercise_numbers ||= {}.tap do |hash|
      exercises_by_ecosystems_and_pages.each do |ecosystem, exercises_by_pages|
        hash[ecosystem] ||= {}

        exercises_by_pages.each do |page, exercises|
          exercises.map(&:number).uniq.each do |number|
            hash[ecosystem][number] ||= []
            hash[ecosystem][number] << page
          end
        end
      end
    end
  end

  def get_exercise_numbers_and_urls_for_exercise_numbers(numbers:)
    numbers.map do |number|
      {
        exercise_number: number,
        exercise_url: exercise_urls_by_exercise_numbers[number]
      }
    end
  end

  def get_page_uuids_and_urls_for_ecosystems_and_exercise_numbers(numbers:, ecosystems: nil)
    (ecosystems || pages_by_ecosystems_and_exercise_numbers.keys).flat_map do |ecosystem|
      pages_by_exercise_numbers = pages_by_ecosystems_and_exercise_numbers[ecosystem] || {}

      numbers.flat_map do |number|
        pages = pages_by_exercise_numbers[number] || []

        pages.map do |page|
          {
            page_uuid: page.uuid,
            page_url: page_urls_by_pages[page]
          }
        end
      end
    end
  end

  def get_teachers_by_course(course:)
    course.teachers.map(&:name).join(', ')
  end

  def exercises_by_course
    excluded_exercises.group_by(&:course).map do |course, excluded_exercises|
      numbers = excluded_exercises.flat_map(&:exercise_number)
      ecosystems = [course.ecosystems.first]
      exercises_hash = get_exercise_numbers_and_urls_for_exercise_numbers(numbers: numbers)
      pages_hash = get_page_uuids_and_urls_for_ecosystems_and_exercise_numbers(
        ecosystems: ecosystems, numbers: numbers
      )

      Hashie::Mash.new(
        course_id: course.id,
        course_name: course.name,
        course_type: course.is_concept_coach ? 'CC' : 'Tutor',
        teachers: get_teachers_by_course(course: course),
        excluded_exercises_count: excluded_exercises.length,
        excluded_exercises_numbers_with_urls: exercises_hash,
        page_uuids_with_urls: pages_hash
      )
    end
  end

  def exercises_by_exercise
    excluded_exercises.group_by(&:exercise_number).map do |number, excluded_exercises|
      exercises_hash = get_exercise_numbers_and_urls_for_exercise_numbers(numbers: [number])
      pages_hash = get_page_uuids_and_urls_for_ecosystems_and_exercise_numbers(numbers: [number])

      Hashie::Mash.new(
        exercise_number: number,
        exercise_url: exercises_hash.first[:exercise_url],
        excluded_exercises_count: excluded_exercises.length,
        pages_with_uuids_and_urls: pages_hash
      )
    end
  end

  def generate_by_course_csv
    CSV.open(filepath_by_course, "w") do |file|
      file.add_row([
        "Course ID",
        "Course Name",
        "Course Type",
        "Teachers",
        "# Exclusions",
        "Excluded Numbers",
        "Excluded Numbers URLs",
        "CNX Section UUID",
        "CNX Section UUID URLs"
      ])

      exercises_by_course.each do |mash|
        file.add_row([
          mash.course_id,
          mash.course_name,
          mash.course_type,
          mash.teachers,
          mash.excluded_exercises_count,
          mash.excluded_exercises_numbers_with_urls.map(&:exercise_number).join(", "),
          mash.excluded_exercises_numbers_with_urls.map(&:exercise_url).join(", "),
          mash.page_uuids_with_urls.map(&:page_uuid).join(", "),
          mash.page_uuids_with_urls.map(&:page_url).join(", ")
        ])
      end
    end
  end

  def generate_by_exercise_csv
    CSV.open(filepath_by_exercise, "w") do |file|
      file.add_row([
        "Exercise Number",
        "Exercise Number URL",
        "# Exclusions",
        "CNX Section UUID(s)",
        "CNX Section UUID(s) URLs"
      ])

      exercises_by_exercise.each do |mash|
        file.add_row([
          mash.exercise_number,
          mash.exercise_url,
          mash.excluded_exercises_count,
          mash.pages_with_uuids_and_urls.map(&:page_uuid).join(", "),
          mash.pages_with_uuids_and_urls.map(&:page_url).join(", ")
        ])
      end
    end
  end

  def owncloud_csv_by_course
    File.join EE_STATS_FOLDER, filename_by_course
  end

  def owncloud_csv_by_exercise
    File.join EE_STATS_FOLDER, filename_by_exercise
  end

  def current_time
    @current_time ||= Time.current.strftime("%Y%m%dT%H%M%SZ")
  end

  def filename_by_course
    "excluded_exercises_stats_by_course_#{current_time}.csv"
  end

  def filename_by_exercise
    "excluded_exercises_stats_by_exercise_#{current_time}.csv"
  end

  def filepath_by_course
    File.join exports_folder, filename_by_course
  end

  def filepath_by_exercise
    File.join exports_folder, filename_by_exercise
  end

  def exports_folder
    File.join 'tmp', 'exports'
  end

  def upload_by_course_csv
    own_cloud_secrets = Rails.application.secrets['owncloud']
    auth = { username: own_cloud_secrets['username'], password: own_cloud_secrets['password'] }

    File.open(filepath_by_course, 'r') do |file|
      HTTParty.put(
        webdav_url(filepath_by_course.split("/").last),
        basic_auth: auth, body_stream: file, headers: { 'Transfer-Encoding' => 'chunked' }
      ).success?
    end
  end

  def upload_by_exercise_csv
    own_cloud_secrets = Rails.application.secrets['owncloud']
    auth = { username: own_cloud_secrets['username'], password: own_cloud_secrets['password'] }

    File.open(filepath_by_exercise, 'r') do |file|
      HTTParty.put(
        webdav_url(filepath_by_exercise.split("/").last),
        basic_auth: auth, body_stream: file, headers: { 'Transfer-Encoding' => 'chunked' }
      ).success?
    end
  end

  def webdav_url(fname)
    Addressable::URI.escape "#{WEBDAV_BASE_URL}/#{fname}"
  end

  def remove_exported_files
    File.delete(filepath_by_course) if File.exists?(filepath_by_course)
    File.delete(filepath_by_exercise) if File.exists?(filepath_by_exercise)
  end
end

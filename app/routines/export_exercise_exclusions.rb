class ExportExerciseExclusions

  lev_routine active_job_enqueue_options: { queue: :long_running }

  protected

  def exec(upload_by_course: false, upload_by_exercise: false)
    if upload_by_course || upload_by_exercise
      if upload_by_course
        generate_by_course_csv
        upload_by_course_csv
      end

      if upload_by_exercise
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
      exercises = Content::Models::Exercise.where(number: all_excluded_exercise_numbers)
                                           .preload(page: :ecosystem)

      exercises.each do |exercise|
        page = exercise.page
        ecosystem = page.ecosystem

        hash[ecosystem] ||= {}
        hash[ecosystem][page] ||= []
        hash[ecosystem][page] << exercise
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

  def get_exercise_hashes_for_exercise_numbers(numbers:)
    numbers.map do |number|
      {
        exercise_number: number,
        exercise_url: exercise_urls_by_exercise_numbers[number]
      }
    end
  end

  def get_page_hashes_for_ecosystems_and_exercise_numbers(numbers:, ecosystems: nil)
    numbers.flat_map do |number|
      hashes = (ecosystems || pages_by_ecosystems_and_exercise_numbers.keys).flat_map do |ecosystem|
        pages_by_exercise_numbers = pages_by_ecosystems_and_exercise_numbers[ecosystem] || {}
        pages = pages_by_exercise_numbers[number] || []

        pages.map do |page|
          {
            page_uuid: page.uuid,
            page_url: page_urls_by_pages[page],
            book_location: page.book_location.join('.')
          }
        end
      end

      hashes.empty? ? [{ page_uuid: 'null', page_url: 'null', book_location: 'null' }] : hashes
    end
  end

  def get_teachers_by_course(course:)
    course.teachers.map(&:name).join(', ')
  end

  def exercises_by_course
    excluded_exercises.group_by(&:course).map do |course, excluded_exercises|
      numbers = excluded_exercises.map(&:exercise_number)
      ecosystem = course.ecosystems.first
      book = ecosystem.try!(:books).try!(:first)
      book_hash = { book_title: book.try!(:title), book_uuid: book.try!(:uuid) }
      exercises_hash = get_exercise_hashes_for_exercise_numbers(numbers: numbers)
      page_hashes = get_page_hashes_for_ecosystems_and_exercise_numbers(
        ecosystems: [ecosystem], numbers: numbers
      )

      Hashie::Mash.new(
        course_id: course.id,
        course_name: course.name,
        course_type: course.is_concept_coach ? 'CC' : 'Tutor',
        teachers: get_teachers_by_course(course: course),
        book_hash: book_hash,
        excluded_exercises_count: excluded_exercises.length,
        excluded_exercises_hash: exercises_hash,
        excluded_ats: excluded_exercises.map(&:created_at),
        page_hashes: page_hashes
      )
    end
  end

  def exercises_by_exercise
    excluded_exercises.group_by(&:exercise_number).map do |number, excluded_exercises|
      exercises_hash = get_exercise_hashes_for_exercise_numbers(numbers: [number])
      page_hashes = get_page_hashes_for_ecosystems_and_exercise_numbers(numbers: [number])

      Hashie::Mash.new(
        exercise_number: number,
        exercise_url: exercises_hash.first[:exercise_url],
        excluded_exercises_count: excluded_exercises.length,
        page_hashes: page_hashes
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
        "Excluded Exercise Numbers",
        "Excluded Exercise URLs",
        "Exclusion Timestamps",
        "CNX Book Title",
        "CNX Book UUID",
        "CNX Book Locations",
        "CNX Page UUIDs",
        "CNX Page URLs"
      ])

      exercises_by_course.each do |mash|
        file.add_row([
          mash.course_id,
          mash.course_name,
          mash.course_type,
          mash.teachers,
          mash.excluded_exercises_count,
          mash.excluded_exercises_hash.map(&:exercise_number).join(", "),
          mash.excluded_exercises_hash.map(&:exercise_url).join(", "),
          mash.excluded_ats.map{ |excluded_at| DateTimeUtilities.to_api_s(excluded_at) }.join(", "),
          mash.book_hash[:book_title],
          mash.book_hash[:book_uuid],
          mash.page_hashes.map(&:book_location).join(", "),
          mash.page_hashes.map(&:page_uuid).join(", "),
          mash.page_hashes.map(&:page_url).join(", ")
        ])
      end
    end
  end

  def generate_by_exercise_csv
    CSV.open(filepath_by_exercise, "w") do |file|
      file.add_row([
        "Excluded Exercise Number",
        "Excluded Exercise URL",
        "# Exclusions",
        "CNX Page UUIDs",
        "CNX Page URLs"
      ])

      exercises_by_exercise.each do |mash|
        file.add_row([
          mash.exercise_number,
          mash.exercise_url,
          mash.excluded_exercises_count,
          mash.page_hashes.map(&:page_uuid).join(", "),
          mash.page_hashes.map(&:page_url).join(", ")
        ])
      end
    end
  end

  def box_csv_by_course
    File.join EXPORT_FOLDER, filename_by_course
  end

  def box_csv_by_exercise
    File.join EXPORT_FOLDER, filename_by_exercise
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
    Box.upload_file filepath_by_course
  end

  def upload_by_exercise_csv
    Box.upload_file filepath_by_exercise
  end

  def remove_exported_files
    File.delete(filepath_by_course) if File.exists?(filepath_by_course)
    File.delete(filepath_by_exercise) if File.exists?(filepath_by_exercise)
  end

end

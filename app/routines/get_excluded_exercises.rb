class GetExcludedExercises
  owncloud_secrets = Rails.application.secrets['owncloud']
  EE_STATS_FOLDER = owncloud_secrets['excluded_exercises_stats_folder'] || "excluded_exercises_stats"
  WEBDAV_BASE_URL = "#{owncloud_secrets['base_url']}/remote.php/webdav/#{EE_STATS_FOLDER}"

  lev_routine

  protected
    def exec(export_by_course: false, export_by_exercise: false)
      if export_by_course
        generate_by_course_csv
        upload_by_course_csv
      end
      if export_by_exercise
        generate_by_exercise_csv
        upload_by_exercise_csv
      end
      unless export_by_course || export_by_exercise
        outputs[:by_course] = ee_by_course
        outputs[:by_exercise] = ee_by_exercise
      end
      remove_exported_files
    end

    def excluded_exercises
      @excluded_exercises ||= CourseContent::Models::ExcludedExercise.preload(
                            course: [
                              :profile, { teachers: { role: { role_user: :profile } } }
                            ]
                          ).sort_by(&:exercise_number)
    end

    def exercises_hash_by_page_uuid
      @exercises_hash_by_page_uuid ||= Content::Models::Exercise.where(number: all_excluded_exercise_numbers)
                                      .preload(:page).group_by{ |ex| ex.page.uuid }
    end

    def all_excluded_exercise_numbers
      @excluded_exercise_numbers ||= excluded_exercises.map(&:exercise_number).uniq
    end

    def get_page_url_by_page_uuid
      @get_page_url_by_page_uuid ||= all_page_urls_by_page_uuids
    end

    def all_page_urls_by_page_uuids
      cnx_page_urls_by_page_uuids = {}
      exercises_hash_by_page_uuid.each do |page_uuid, exercises|
        page_url = OpenStax::Cnx::V1.webview_url_for(page_uuid) # URL
        cnx_page_urls_by_page_uuids[page_uuid] = page_url
      end
      cnx_page_urls_by_page_uuids
    end

    def exercise_urls_by_exercise_number
      @exercise_urls_by_exercise_numbers ||= all_exercise_urls_by_exercise_numbers
    end

    def all_exercise_urls_by_exercise_numbers
      exercise_urls = {}
      all_excluded_exercise_numbers.each do |number|
        exercise_url = OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s # URL
        exercise_urls[number] = exercise_url
      end
      exercise_urls
    end

    def page_uuids_by_exercise_numbers
      @page_uuids_by_exercise_numbers ||= all_page_uuids_by_exercise_numbers
    end

    def all_page_uuids_by_exercise_numbers
      uuids = Hash.new{ |hash, key| hash[key] = [] }
      exercises_hash_by_page_uuid.map do |page_uuid, exercises|
        exercises.map(&:number).uniq.each do |number|
          uuids[number] << page_uuid
        end
      end
      uuids
    end

    def get_ee_numbers_with_urls_by_ee(e_numbers = [])
      ee_and_urls = []
      e_numbers.each {|number|
        ee_and_urls << {
          ee_number: number,
          ee_url: exercise_urls_by_exercise_number[number]
        }
      }
      ee_and_urls
    end

    def get_page_uuids_and_urls_by_ee_numbers(numbers = [])
      uuids_and_urls = []
      numbers.map { |e_number|
        page_uuids = page_uuids_by_exercise_numbers[e_number] || []

        page_uuids.each { |page_uuid|
          uuids_and_urls << {
            page_uuid: page_uuid,
            page_url: get_page_url_by_page_uuid[page_uuid]
          }
        }
      }
      uuids_and_urls
    end

    def get_teachers_by_course(course)
      return "" unless course && course.teachers
      course.teachers.map{ |teacher| teacher.role.name }.join(', ')
    end

    def ee_by_course
      excluded_exercises.group_by(&:course).map do |course, course_excluded_exercises|
        Hashie::Mash.new({
            course_id: course.id,
            course_name: course.profile.try(:name),
            teachers: get_teachers_by_course(course),
            excluded_exercises_count: course_excluded_exercises.length,
            excluded_exercises_numbers_with_urls: get_ee_numbers_with_urls_by_ee(course_excluded_exercises.flat_map(&:exercise_number)),
            page_uuids_with_urls: get_page_uuids_and_urls_by_ee_numbers(course_excluded_exercises.flat_map(&:exercise_number))
        })
      end
    end

    def ee_by_exercise
      excluded_exercises.group_by(&:exercise_number).map do |number, exercise_number_excluded_exercises|
        Hashie::Mash.new({
          exercise_number: number,
          exercise_url: get_ee_numbers_with_urls_by_ee([number]).first[:ee_url],
          excluded_exercises_count: exercise_number_excluded_exercises.length,
          pages_with_uuids_and_urls: get_page_uuids_and_urls_by_ee_numbers([number])
        })
      end
    end

    def generate_by_course_csv
      CSV.open(filepath_by_course, "w") do |file|
        file.add_row([
                  "Course ID",
                  "Course Name",
                  "Teachers",
                  "# Exclusions",
                  "Excluded Numbers",
                  "Excluded Numbers URLs",
                  "CNX Section UUID",
                  "CNX Section UUID URLs"
                ])

        ee_by_course.each do |ee|
          file.add_row([
                      ee.course_id,
                      ee.course_name,
                      ee.teachers,
                      ee.excluded_exercises_count,
                      ee.excluded_exercises_numbers_with_urls.map(&:ee_number).join(", "),
                      ee.excluded_exercises_numbers_with_urls.map(&:ee_url).join(", "),
                      ee.page_uuids_with_urls.map(&:page_uuid).join(", "),
                      ee.page_uuids_with_urls.map(&:page_url).join(", ")
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

        ee_by_exercise.each do |ee|
          file.add_row([
                      ee.exercise_number,
                      ee.exercise_url,
                      ee.excluded_exercises_count,
                      ee.pages_with_uuids_and_urls.map(&:page_uuid).join(", "),
                      ee.pages_with_uuids_and_urls.map(&:page_url).join(", ")
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

    def filename_by_course
      "excluded_exercises_stats_by_course_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
    end

    def filename_by_exercise
      "excluded_exercises_stats_by_exercise_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
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
        HTTParty.put(webdav_url(filepath_by_course.split("/").last), basic_auth: auth, body_stream: file,
                     headers: { 'Transfer-Encoding' => 'chunked' }
        ).success?
      end
    end

    def upload_by_exercise_csv
      own_cloud_secrets = Rails.application.secrets['owncloud']
      auth = { username: own_cloud_secrets['username'], password: own_cloud_secrets['password'] }

      File.open(filepath_by_exercise, 'r') do |file|
        HTTParty.put(webdav_url(filepath_by_exercise.split("/").last), basic_auth: auth, body_stream: file,
                     headers: { 'Transfer-Encoding' => 'chunked' }
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

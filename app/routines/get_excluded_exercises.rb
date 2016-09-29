class GetExcludedExercises
  lev_routine

  protected
    def exec
      @excluded_exercises = CourseContent::Models::ExcludedExercise.preload(
                            course: [
                              :profile, { teachers: { role: { role_user: :profile } } }
                            ]
                          ).sort_by(&:exercise_number)

      all_excluded_exercise_numbers = @excluded_exercises.map(&:exercise_number).uniq

      @exercises_hash_by_page_uuid = Content::Models::Exercise.where(number: all_excluded_exercise_numbers)
                                      .preload(:page).group_by{ |ex| ex.page.uuid }.to_hash

      @page_uuids_by_exercise_numbers = get_all_page_uuids_by_exercise_numbers
      @get_page_url_by_page_uuid = get_all_page_urls_by_page_uuids
      @exercise_urls_by_exercise_numbers = get_all_exercise_urls_by_exercise_numbers(all_excluded_exercise_numbers)

      outputs[:by_course] = ee_by_course
      outputs[:by_exercise] = ee_by_exercise
    end

    def get_all_page_urls_by_page_uuids
      cnx_page_urls_by_page_uuids = {}

      @exercises_hash_by_page_uuid.each do |page_uuid, exercises|
        page_url = OpenStax::Cnx::V1.webview_url_for(page_uuid) # URL
        exercises.map(&:number).uniq.each do |ee_number|
          @page_uuids_by_exercise_numbers[ee_number] << page_uuid
        end

        cnx_page_urls_by_page_uuids[page_uuid] = page_url
      end

      cnx_page_urls_by_page_uuids
    end

    def get_all_exercise_urls_by_exercise_numbers(all_excluded_exercise_numbers = [])
      exercise_urls = {}
      all_excluded_exercise_numbers.each do |number|
        exercise_url = OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s # URL
        exercise_urls[number] = exercise_url
      end
      exercise_urls
    end

    def get_all_page_uuids_by_exercise_numbers
      uuids = Hash.new{ |hash, key| hash[key] = [] }
      @exercises_hash_by_page_uuid.map do |page_uuid, exercises|
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
          ee_url: @exercise_urls_by_exercise_numbers[number]
        }
      }

      ee_and_urls
    end

    def get_page_uuids_and_urls_by_ee_numbers(numbers = [])
      uuids_and_urls = []

      numbers.map { |e_number|
        page_uuids = @page_uuids_by_exercise_numbers[e_number] || []

        page_uuids.each { |page_uuid|
          uuids_and_urls << {
            page_uuid: page_uuid,
            page_url: @get_page_url_by_page_uuid[page_uuid]
          }
        }
      }

      uuids_and_urls
    end

    def get_teachers_by_course(course)
      course.teachers.map{ |teacher| teacher.role.name }.join(', ')
    end

    def ee_by_course
      @excluded_exercises.group_by(&:course).map do |course, excluded_exercises|
        Hashie::Mash.new({
            course_id: course.id,
            course_name: course.name,
            teachers: get_teachers_by_course(course),
            ee_count: excluded_exercises.length,
            ee_numbers_with_urls: get_ee_numbers_with_urls_by_ee(excluded_exercises.flat_map(&:exercise_number)),
            page_uuids_with_urls: get_page_uuids_and_urls_by_ee_numbers(excluded_exercises.flat_map(&:exercise_number))
        })
      end
    end

    def ee_by_exercise
      @excluded_exercises.group_by(&:exercise_number).map do |number, excluded_exercises|
        Hashie::Mash.new({
          ee_number: number,
          ee_url: get_ee_numbers_with_urls_by_ee([number]).first[:ee_url],
          ee_count: excluded_exercises.length,
          pages_with_uuids_and_urls: get_page_uuids_and_urls_by_ee_numbers([number])
        })
      end
    end
end

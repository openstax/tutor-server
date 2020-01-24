module OpenStax::Biglearn::Interface
  protected

  def self.extended(base)
    base.extend Configurable
    base.extend Configurable::ClientMethods
  end

  def extract_options(args_array, option_keys = [])
    num_args = args_array.size
    requests = args_array.first

    case num_args
    when 1
      case requests
      when Hash
        options = requests
        requests = requests.except(*option_keys)
      when Array
        options = requests.last.is_a?(Hash) ? requests.last : {}
        last_request = options.except(*option_keys)
        requests = requests[0..-2]
        requests << last_request unless last_request.blank?
      else
        options = {}
      end
    when 2
      options = args_array.last
    else
      raise ArgumentError, "wrong number of arguments (#{num_args} for 1..2)", caller
    end

    [requests, options.slice(*option_keys)]
  end

  def verify_and_slice_request(method:, request:, keys: [], optional_keys: [])
    required_keys = [keys].flatten
    missing_keys = required_keys.reject { |key| request.has_key? key }

    raise(
      OpenStax::Biglearn::MalformedRequest,
      "Invalid request: #{method} request #{request.inspect
      } is missing these required key(s): #{missing_keys.inspect}"
    ) if missing_keys.any?

    optional_keys = [optional_keys].flatten
    request_keys = required_keys + optional_keys

    request.slice(*request_keys)
  end

  def verify_result(result:, result_class: Hash)
    results_array = [result].flatten

    results_array.each do |result|
      raise(
        OpenStax::Biglearn::ResultTypeError,
        "Invalid result: #{result} has type #{result.class.name
        } but expected type was #{result_class.name}"
      ) if result.class != result_class
    end

    result
  end

  def get_ecosystem_exercises_by_uuids(ecosystem:, exercise_uuids:, max_num_exercises: nil,
                                       accepted: true, task: nil, enable_warnings: nil)
    enable_warnings = true if enable_warnings.nil?

    if accepted
      exercises_by_uuid = ecosystem.exercises.where(uuid: exercise_uuids).index_by(&:uuid)
      ordered_exercises = exercise_uuids.map do |uuid|
        exercises_by_uuid[uuid].tap do |exercise|
          raise(
            OpenStax::Biglearn::ExercisesError, "Biglearn returned exercises not present locally"
          ) if exercise.nil?
        end
      end

      unless max_num_exercises.nil?
        number_returned = exercise_uuids.length

        raise(
          OpenStax::Biglearn::ExercisesError, "Biglearn returned more exercises than requested"
        ) if !max_num_exercises.nil? && number_returned > max_num_exercises

        Rails.logger.warn do
          "Biglearn returned less exercises than requested (#{
          number_returned} instead of #{max_num_exercises})"
        end if !max_num_exercises.nil? && number_returned < max_num_exercises

        ordered_exercises = ordered_exercises.first(max_num_exercises)
      end

      ordered_exercises.map { |exercise| Content::Exercise.new strategy: exercise.wrap }
    else
      # Fallback in case Biglearn fails to respond in a timely manner
      # We just assign personalized exercises for the current assignment
      # regardless of what the original slot was
      return [] if task.nil? || max_num_exercises.nil?

      course_member = task.taskings.first&.role&.course_member
      return [] if course_member.nil?

      course = course_member.course

      core_page_ids = GetTaskCorePageIds[tasks: task][task.id]
      pages = ecosystem.pages.where(id: core_page_ids)
      if task.reading?
        pool_method = :reading_dynamic_pool
      elsif task.homework?
        pool_method = :homework_dynamic_pool
      else
        return []
      end
      pools = pages.map { |page| page.public_send(pool_method) }

      task_exercise_ids = Set.new task.tasked_exercises.pluck(:content_exercise_id)
      pool_exercises = pools.flat_map(&:exercises).uniq
      filtered_exercises = FilterExcludedExercises[exercises: pool_exercises, course: course]
      candidate_exercises = filtered_exercises.reject do |exercise|
        task_exercise_ids.include?(exercise.id)
      end

      candidate_exercises.sample(max_num_exercises).tap do |chosen_exercises|
        WarningMailer.log_and_deliver(
          subject: 'Tutor assigned fallback exercises for Biglearn',
          message: <<~WARNING
            #{task.task_type.humanize} Task ID: #{task.id}, UUID: #{task.uuid}
            #{course_member.class.name} ID: #{course_member.id}, UUID: #{course_member.uuid}
            Course ID: #{course.id}, UUID: #{course.uuid}
            Number of fallback exercises: #{chosen_exercises.size}
          WARNING
        ) if enable_warnings && !chosen_exercises.empty?
      end
    end
  end
end

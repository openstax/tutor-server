class WorkPreviewCourseTasks
  GREAT_STUDENT_CORRECT_PROBABILITY = 0.95
  AVERAGE_STUDENT_CORRECT_PROBABILITY = 0.8
  STRUGGLING_STUDENT_CORRECT_PROBABILITY = 0.65

  FREE_RESPONSE = 'This is where you can see each student’s answer in his or her own words.'

  lev_routine active_job_enqueue_options: { queue: :preview, wait: 60.seconds }

  uses_routine Preview::WorkTask, as: :work_task

  def exec(course:)
    course.periods.each do |period|
      student_roles = period.student_roles.sort_by(&:created_at)

      next if student_roles.empty?

      ActiveRecord::Associations::Preloader.new.preload(
        student_roles, taskings: { task: [ :course, { task_steps: :tasked } ] }
      )

      all_tasks = student_roles.flat_map { |role| role.taskings.map(&:task) }

      pe_requests = all_tasks.map do |task|
        max_num_exercises =
          task.task_steps.select(&:placeholder?).select(&:personalized_group?).size
        next if max_num_exercises == 0

        {
          request_uuid: SecureRandom.uuid,
          task: task,
          max_num_exercises: max_num_exercises,
          inline_max_attempts: 60,
          inline_sleep_interval: 1.second
        }
      end.compact

      spe_requests = all_tasks.map do |task|
        max_num_exercises =
          task.task_steps.select(&:placeholder?).select(&:spaced_practice_group?).size
        next if max_num_exercises == 0

        {
          request_uuid: SecureRandom.uuid,
          task: task,
          max_num_exercises: max_num_exercises,
          inline_max_attempts: 60,
          inline_sleep_interval: 1.second
        }
      end.compact

      great_student_role = student_roles.first
      current_time = Time.current

      work_tasks(
        role: great_student_role,
        correct_probability: GREAT_STUDENT_CORRECT_PROBABILITY,
        current_time: current_time
      )

      next if student_roles.size < 2

      struggling_student_role = student_roles.last

      work_tasks(
        role: struggling_student_role,
        correct_probability: STRUGGLING_STUDENT_CORRECT_PROBABILITY,
        late: true,
        incomplete: true,
        current_time: current_time
      )

      next if student_roles.size < 3

      average_student_roles = student_roles[1..-2]

      average_student_roles.each do |role|
        work_tasks(
          role: role,
          correct_probability: AVERAGE_STUDENT_CORRECT_PROBABILITY,
          current_time: current_time
        )
      end

      Tasks::UpdateTaskCaches.call task_ids: all_tasks.map(&:id)
    end

    # The course is now ready to be claimed
    course.update_attribute :is_preview_ready, true
  end

  protected

  def work_tasks(
    role:, correct_probability:, late: false, incomplete: false, current_time: Time.current
  )
    tasks = role.taskings.map(&:task).reject { |task| task.opens_at > current_time }

    tasks.each do |task|
      is_correct   = ->(task_step, index) { SecureRandom.random_number < correct_probability }
      is_completed = ->(task_step, index) { !incomplete || index < task.task_steps.size/2    }
      completed_at = [late ? task.due_at + 1.day : task.due_at - 1.day, current_time].min

      run(
        :work_task,
        task: task,
        free_response: FREE_RESPONSE,
        is_correct: is_correct,
        is_completed: is_completed,
        completed_at: completed_at
      )
    end
  end
end

module Tasks
  class GetTpPerformanceReport
    include PerformanceReportRoutine

    # Overall average score and heading stats do not include dropped student data

    lev_routine express_output: :performance_report

    protected

    def exec(course:, role: nil, is_teacher: nil)
      raise ArgumentError, 'you must supply the role when is_teacher is not true' \
        if role.nil? && !is_teacher

      is_teacher = CourseMembership::IsCourseTeacher[course: course, roles: [role]] \
        if is_teacher.nil?

      periods = if is_teacher
        course.periods.reject(&:archived?)
      else
        raise(SecurityTransgression) \
          if role.student.nil? || role.student.course_profile_course_id != course.id

        [ role.student.period ]
      end

      tz = course.time_zone.try!(:to_tz) || Time.zone
      current_time_ntz = DateTimeUtilities.remove_tz(tz.now)

      tasks = get_course_tasks(course, role, is_teacher, current_time_ntz)
      tasks_by_period_id = tasks.group_by(&:course_membership_period_id)

      outputs.performance_report = periods.map do |period|
        period_tasks = tasks_by_period_id[period.id] || []
        tasking_plans = filter_and_sort_tasking_plans(period_tasks, course, period)

        # Assign column numbers in the performance report to task_plans
        col_nums_by_task_plan_id = {}
        tasking_plans.each_with_index do |tasking_plan, col_num|
          col_nums_by_task_plan_id[tasking_plan.tasks_task_plan_id] = col_num
        end

        # Sort the students into the performance report rows by name
        period_tasks_by_role_id = period_tasks.group_by(&:role_id)
        sorted_role_id_tasks_array = period_tasks_by_role_id.sort_by do |_, tasks|
          first_task = tasks.first
          name = "#{first_task.last_name} #{first_task.first_name}"
          name = first_task.username if name.blank?
          name.downcase
        end

        # This hash will accumulate student tasks to calculate header stats later
        task_plan_id_to_task_map = Hash.new { |hash, key| hash[key] = [] }
        student_data = sorted_role_id_tasks_array.map do |role_id, tasks|
          first_task = tasks.first

          name = "#{first_task.first_name} #{first_task.last_name}"
          name = first_task.username if name.blank?

          # Populate the student_tasks array but leave empty spaces (nils)
          # for assignments the student hasn't done
          student_tasks = Array.new(tasking_plans.size)

          tasks.each do |task|
            col_num = col_nums_by_task_plan_id[task.tasks_task_plan_id]
            # Skip if there is no column in the report for this task
            # (which means it is not assigned to the current period)
            # Could be individual, like practice widget, or assigned
            # only to a different period and done by the student before transferring
            next if col_num.nil?

            student_tasks[col_num] = task
          end

          is_dropped = !first_task.dropped_at.nil?

          # Gather the non-dropped student tasks into the task_plan_id_to_task_map hash
          student_tasks.compact.each do |task|
            task_plan_id_to_task_map[task.tasks_task_plan_id] << task
          end if !is_dropped

          data = get_task_data(
            tasks: student_tasks, tz: tz, current_time_ntz: current_time_ntz, is_teacher: is_teacher
          )
          non_nil_data = data.compact
          homework_tasks = non_nil_data.select { |dd| dd.type == 'homework' }.map(&:task)
          reading_tasks = non_nil_data.select { |dd| dd.type == 'reading' }.map(&:task)

          homework_score = average_score(
            tasks: homework_tasks, current_time_ntz: current_time_ntz, is_teacher: is_teacher
          )
          homework_progress = average_progress(
            tasks: homework_tasks, current_time_ntz: current_time_ntz
          )
          reading_score = average_score(
            tasks: reading_tasks, current_time_ntz: current_time_ntz, is_teacher: is_teacher
          )
          reading_progress = average_progress(
            tasks: reading_tasks, current_time_ntz: current_time_ntz
          )

          homework_score_weight = course.homework_score_weight.to_f
          homework_progress_weight = course.homework_progress_weight.to_f
          reading_score_weight = course.reading_score_weight.to_f
          reading_progress_weight = course.reading_progress_weight.to_f

          course_average = if (homework_score_weight    > 0 && homework_score.nil?   ) ||
                              (homework_progress_weight > 0 && homework_progress.nil?) ||
                              (reading_score_weight     > 0 && reading_score.nil?    ) ||
                              (reading_progress_weight  > 0 && reading_progress.nil? )
            nil
          else
            homework_score_weight    * (homework_score    || 0) +
            homework_progress_weight * (homework_progress || 0) +
            reading_score_weight     * (reading_score     || 0) +
            reading_progress_weight  * (reading_progress  || 0)
          end

          OpenStruct.new(
            name: name,
            first_name: first_task.first_name,
            last_name: first_task.last_name,
            student_identifier: first_task.student_identifier,
            role: role_id,
            user: first_task.user_id,
            data: data,
            homework_score: homework_score,
            homework_progress: homework_progress,
            reading_score: reading_score,
            reading_progress: reading_progress,
            course_average: course_average,
            is_dropped: is_dropped
          )
        end

        overall_students = student_data.reject(&:is_dropped)
        OpenStruct.new(
          period: period,
          overall_homework_score: average(array: overall_students.map(&:homework_score)),
          overall_homework_progress: average(array: overall_students.map(&:homework_progress)),
          overall_reading_score: average(array: overall_students.map(&:reading_score)),
          overall_reading_progress: average(array: overall_students.map(&:reading_progress)),
          overall_course_average: average(array: overall_students.map(&:course_average)),
          data_headings: get_data_headings(
            tasking_plans, task_plan_id_to_task_map, tz, current_time_ntz, is_teacher
          ),
          students: student_data
        )
      end
    end

    # Return reading, homework and external tasks for a student
    # reorder(nil) is required for distinct to work
    # distinct is required for preloading to work
    def get_course_tasks(course, role, is_teacher, current_time_ntz)
      task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework, :external)
      tt = Tasks::Models::Task.arel_table
      er = Entity::Role.arel_table
      st = CourseMembership::Models::Student.arel_table
      up = User::Models::Profile.arel_table
      ac = OpenStax::Accounts::Account.arel_table
      rel = Tasks::Models::Task
        .select(
          [
            tt[ Arel.star ],
            er[:id].as('role_id'),
            st[:student_identifier],
            st[:course_membership_period_id],
            st[:dropped_at],
            up[:id].as('user_id'),
            ac[:username],
            ac[:first_name],
            ac[:last_name]
          ]
        )
        .joins(
          task_plan: :tasking_plans,
          taskings: { role: [ :student, profile: :account ] }
        )
        .where(
          task_type: task_types,
          task_plan: { withdrawn_at: nil },
          taskings: { role: { student: { course_profile_course_id: course.id } } }
        )
        .where(tt[:opens_at_ntz].eq(nil).or tt[:opens_at_ntz].lteq(current_time_ntz))
        .preload(task_plan: :tasking_plans)
        .reorder(nil).distinct

      rel = rel.joins(:taskings).where(taskings: { entity_role_id: role.id }) unless is_teacher

      rel.to_a
    end

    def filter_and_sort_tasking_plans(tasks, course, period)
      tasks.map(&:task_plan).select(&:is_published?).flat_map do |task_plan|
        task_plan.tasking_plans.select do |tp|
          case tp.target_type
          when CourseProfile::Models::Course.name
            tp.target_id == course.id
          when CourseMembership::Models::Period.name
            tp.target_id == period.id
          end
        end
      end.uniq.sort_by { |tp| [ tp.due_at_ntz, tp.created_at ] }.reverse
    end

    def get_data_headings(tasking_plans, task_plan_id_to_task_map, tz, current_time_ntz, is_teacher)
      tasking_plans.map do |tasking_plan|
        task_plan = tasking_plan.task_plan
        task_plan_id = task_plan.id
        tasks = task_plan_id_to_task_map[task_plan_id]

        OpenStruct.new(
          plan_id: task_plan_id,
          title: task_plan.title,
          type: task_plan.type,
          due_at: DateTimeUtilities.apply_tz(tasking_plan.due_at_ntz, tz),
          average_score: average_score(
            tasks: tasks, current_time_ntz: current_time_ntz, is_teacher: is_teacher
          ),
          average_progress: average_progress(tasks: tasks, current_time_ntz: current_time_ntz)
        )
      end
    end
  end
end

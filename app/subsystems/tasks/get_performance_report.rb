module Tasks
  class GetPerformanceReport
    # Overall average score and heading stats do not include dropped student data

    lev_routine express_output: :performance_report

    protected

    def exec(course:, role: nil, is_teacher: nil, is_frozen: nil, current_time: Time.current)
      raise ArgumentError, 'you must supply the role when is_teacher is not true' \
        if role.nil? && !is_teacher

      is_teacher = CourseMembership::IsCourseTeacher[course: course, roles: [role]] \
        if is_teacher.nil?

      is_frozen = is_teacher && course.frozen_scores?(current_time) if is_frozen.nil?

      if is_frozen
        outputs.performance_report = course.cache.teacher_performance_report.map do |report|
          Hashie::Mash.new report
        end

        return unless outputs.performance_report.nil?
      end

      roles_by_period_id = {}
      if is_teacher
        periods = course.periods.preload(
          students: { role: { profile: :account } }
        ).reject(&:archived?)

        periods.each { |period| roles_by_period_id[period.id] = period.students.map(&:role) }
      else
        member = role.course_member

        raise(SecurityTransgression) \
          if member.nil? || member.course_profile_course_id != course.id

        periods = [ member.period ]
        roles_by_period_id[member.period.id] = [ role ]
      end

      tz = course.time_zone
      current_time = tz.now

      tasks_by_role_id = get_past_due_tasks_by_role_id(
        roles_by_period_id.values.flatten, current_time
      )

      pre_wrm = course.pre_wrm_scores?

      outputs.performance_report = periods.map do |period|
        roles = roles_by_period_id[period.id] || []
        period_tasks = tasks_by_role_id.values_at(*roles.map(&:id)).compact.flatten
        tasking_plans = filter_and_sort_tasking_plans(period_tasks, course, period)

        # Assign column numbers in the performance report to task_plans
        col_nums_by_task_plan_id = {}
        tasking_plans.each_with_index do |tasking_plan, col_num|
          col_nums_by_task_plan_id[tasking_plan.tasks_task_plan_id] = col_num
        end

        # This hash will accumulate student tasks to calculate header stats later
        task_plan_id_to_task_map = Hash.new { |hash, key| hash[key] = [] }

        # Sort the students into the performance report rows by name
        student_data = roles.sort_by do |rr|
          name = "#{rr.last_name} #{rr.first_name}"
          name = rr.username if name.blank?
          name.downcase
        end.map do |rr|
          tasks = tasks_by_role_id[rr.id] || []

          name = "#{rr.first_name} #{rr.last_name}"
          name = rr.username if name.blank?

          # Populate the task_scores array but leave empty spaces (nils)
          # for assignments the student hasn't done
          tasks_for_columns = Array.new(tasking_plans.size)

          tasks.each do |task|
            col_num = col_nums_by_task_plan_id[task.tasks_task_plan_id]
            # Skip if there is no column in the report for this task
            # (which means it is not assigned to the current period)
            # Could be individual, like practice widget, or assigned
            # only to a different period and done by the student before transferring
            next if col_num.nil?

            tasks_for_columns[col_num] = task
          end

          case rr.role_type
          when 'student'
            student = rr.student
            is_dropped = !student.dropped_at.nil?
            student_identifier = student.student_identifier
          when 'teacher_student'
            is_dropped = !rr.teacher_student.deleted_at.nil?
            student_identifier = ''
          end

          # Gather the non-dropped student tasks into the task_plan_id_to_task_map hash
          tasks_for_columns.compact.each do |task|
            task_plan_id_to_task_map[task.tasks_task_plan_id] << task
          end unless is_dropped

          data = get_task_data(
            pre_wrm: pre_wrm,
            tasks: tasks_for_columns,
            tz: tz,
            current_time: current_time,
            is_teacher: is_teacher
          )
          non_nil_data = data.compact
          homework_tasks = non_nil_data.select { |dd| dd.type == 'homework' }.map(&:task)
          reading_tasks =  non_nil_data.select { |dd| dd.type == 'reading'  }.map(&:task)

          homework_score = average_score(
            pre_wrm: pre_wrm,
            tasks: homework_tasks,
            current_time: current_time,
            is_teacher: is_teacher
          )
          homework_progress = average_progress(
            pre_wrm: pre_wrm,
            tasks: homework_tasks,
            current_time: current_time
          )
          reading_score = average_score(
            pre_wrm: pre_wrm,
            tasks: reading_tasks,
            current_time: current_time,
            is_teacher: is_teacher
          )
          reading_progress = average_progress(
            pre_wrm: pre_wrm,
            tasks: reading_tasks,
            current_time: current_time
          )

          homework_weight = course.homework_weight.to_f
          reading_weight = course.reading_weight.to_f

          if pre_wrm
            # Old courses should have only 1 set of weights for grading templates of the same type
            homework_grading_template = course.grading_templates.detect(&:homework?)
            homework_score_weight = homework_weight * (
              homework_grading_template&.correctness_weight || 1.0
            )
            homework_progress_weight = homework_weight * (
              homework_grading_template&.completion_weight || 0.0
            )

            reading_grading_template = course.grading_templates.detect(&:reading?)
            reading_score_weight = reading_weight * (
              reading_grading_template&.correctness_weight || 0.1
            )
            reading_progress_weight = reading_weight * (
              reading_grading_template&.completion_weight || 0.9
            )

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
          else
            course_average = if (homework_weight > 0 && homework_score.nil?) ||
                                (reading_weight  > 0 && reading_score.nil? )
              nil
            else
              homework_weight * (homework_score || 0) + reading_weight  * (reading_score  || 0)
            end
          end

          Hashie::Mash.new(
            name: name,
            first_name: rr.first_name,
            last_name: rr.last_name,
            role: rr.id,
            user: rr.user_profile_id,
            student_identifier: student_identifier,
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
        Hashie::Mash.new(
          period: period,
          overall_homework_score: average(array: overall_students.map(&:homework_score)),
          overall_homework_progress: average(array: overall_students.map(&:homework_progress)),
          overall_reading_score: average(array: overall_students.map(&:reading_score)),
          overall_reading_progress: average(array: overall_students.map(&:reading_progress)),
          overall_course_average: average(array: overall_students.map(&:course_average)),
          data_headings: get_data_headings(
            pre_wrm, tasking_plans, task_plan_id_to_task_map, tz, current_time, is_teacher
          ),
          students: student_data
        )
      end
    end

    # Return reading, homework and external tasks for the given roles
    # reorder(nil) is required for distinct to work
    # distinct is required for preloading to work
    def get_past_due_tasks_by_role_id(roles, current_time)
      task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework, :external)
      tt = Tasks::Models::Task.arel_table
      er = Entity::Role.arel_table
      Tasks::Models::Task
        .select([ tt[Arel.star], er[:id].as('"role_id"') ])
        .joins(:course, task_plan: :tasking_plans, taskings: { role: [ profile: :account ] })
        .where(task_type: task_types, task_plan: { withdrawn_at: nil }, taskings: { role: roles })
        .where(
          <<~WHERE_SQL
            TIMEZONE(
              "course_profile_courses"."timezone", "tasks_tasks"."due_at_ntz"
            ) <= '#{current_time}'
          WHERE_SQL
        )
        .preload(:taskings, :course, task_plan: [ :tasking_plans, :course, :extensions ])
        .reorder(nil)
        .distinct
        .group_by(&:role_id)
    end

    def filter_and_sort_tasking_plans(tasks, course, period)
      tasks.map(&:task_plan).select(&:is_published?).flat_map do |task_plan|
        task_plan.tasking_plans.filter do |tp|
          case tp.target_type
          when CourseProfile::Models::Course.name
            tp.target_id == course.id
          when CourseMembership::Models::Period.name
            tp.target_id == period.id
          end
        end
      end.uniq.sort_by { |tp| [ tp.due_at, tp.closes_at, tp.created_at ] }.reverse
    end

    def get_data_headings(
      pre_wrm, tasking_plans, task_plan_id_to_task_map, tz, current_time, is_teacher
    )
      tasking_plans.map do |tasking_plan|
        task_plan = tasking_plan.task_plan
        task_plan_id = task_plan.id
        tasks = task_plan_id_to_task_map[task_plan_id]
        longest_task = tasks.max_by(&:actual_and_placeholder_exercise_count)

        Hashie::Mash.new(
          plan_id: task_plan_id,
          title: task_plan.title,
          type: task_plan.type,
          available_points: longest_task&.available_points,
          due_at: tasking_plan.due_at,
          average_score: average_score(
            pre_wrm: pre_wrm,
            tasks: tasks,
            current_time: current_time,
            is_teacher: is_teacher
          ),
          average_progress: average_progress(
            pre_wrm: pre_wrm,
            tasks: tasks,
            current_time: current_time
          )
        )
      end
    end

    def included_in_progress_averages?(task:)
      task.steps_count > 0
    end

    def included_in_score_averages?(task:, current_time:, is_teacher:)
      task.actual_and_placeholder_exercise_count > 0 &&
      included_in_progress_averages?(task: task) && (
        is_teacher || task.feedback_available?(current_time: current_time)
      )
    end

    def completion_fraction(tasks:)
      completed_count = tasks.count { |tt| tt.completed?(use_cache: true) }

      completed_count.to_f / tasks.count
    end

    def average_score(pre_wrm:, tasks:, current_time:, is_teacher:)
      applicable_tasks = tasks.compact.select do |task|
        included_in_score_averages?(
          task: task, current_time: current_time, is_teacher: is_teacher
        )
      end

      return nil if applicable_tasks.empty?

      average(
        array: applicable_tasks,
        value_getter: ->(task) { pre_wrm ? pre_wrm_score(task) : task.published_score }
      )
    end

    def average_progress(pre_wrm:, tasks:, current_time:)
      applicable_tasks = tasks.compact.select do |task|
        included_in_progress_averages?(task: task)
      end

      return nil if applicable_tasks.empty?

      average(
        array: applicable_tasks,
        value_getter: ->(task) { pre_wrm ? pre_wrm_progress(task) : task.completion }
      )
    end

    def average(array:, value_getter: nil)
      values = array.map { |item| value_getter.nil? ? item : value_getter.call(item) }.compact
      num_values = values.length
      return if num_values == 0

      values.sum / num_values.to_f
    end

    def pre_wrm_progress(task)
      task.completed_on_time_steps_count.to_f / task.steps_count
    end

    def pre_wrm_score(task)
      task.correct_on_time_exercise_steps_count.to_f / task.actual_and_placeholder_exercise_count
    end

    def get_task_data(pre_wrm:, tasks:, tz:, current_time:, is_teacher:)
      tasks.map do |tt|
        # Skip if the student hasn't worked this particular task_plan/page
        next if tt.nil?
        show_score = is_teacher || tt.feedback_available?(current_time: current_time)
        correct_exercise_count = show_score ? tt.correct_exercise_count : nil
        type = tt.task_type

        if pre_wrm
          available_points = tt.actual_and_placeholder_exercise_count
          progress = pre_wrm_progress tt
          published_points = tt.correct_on_time_exercise_steps_count
          published_score = pre_wrm_score tt
        else
          available_points = tt.available_points
          progress = tt.completion
          published_points = tt.published_points
          published_score = tt.published_score
        end

        Hashie::Mash.new(
          task:                                   tt,
          status:                                 tt.status(use_cache: true),
          type:                                   type,
          id:                                     tt.id,
          due_at:                                 tt.due_at,
          step_count:                             tt.steps_count,
          completed_step_count:                   tt.completed_steps_count,
          completed_on_time_steps_count:          tt.completed_on_time_steps_count,
          available_points:                       available_points,
          progress:                               progress,
          published_points:                       published_points,
          published_score:                        published_score,
          is_provisional_score:                   tt.provisional_score?,
          # the below fields are only used by old scores report
          actual_and_placeholder_exercise_count:  tt.actual_and_placeholder_exercise_count,
          correct_exercise_count:                 correct_exercise_count,
          last_worked_at:                         tt.last_worked_at&.in_time_zone(tz)
        )
      end
    end
  end
end

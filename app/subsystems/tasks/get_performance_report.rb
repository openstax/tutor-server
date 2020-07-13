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
        outputs.performance_report = course.teacher_performance_report.map do |report|
          Hashie::Mash.new report
        end

        return unless outputs.performance_report.nil?
      end

      periods = []
      if is_teacher
        periods = course.periods.reject(&:archived?)
      else
        member = role.course_member

        raise(SecurityTransgression) \
          if member.nil? || member.course_profile_course_id != course.id

        periods = [ member.period ]
      end

      tz = course.time_zone
      current_time = tz.now

      tasks = get_course_tasks(course, role, is_teacher, current_time)
      tasks_by_period_id = tasks.group_by(&:course_membership_period_id)

      pre_wrm = course.pre_wrm_scores?

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
            pre_wrm: pre_wrm,
            tasks: student_tasks,
            tz: tz,
            current_time: current_time,
            is_teacher: is_teacher
          )
          non_nil_data = data.compact
          homework_tasks = non_nil_data.select { |dd| dd.type == 'homework' }.map(&:task)
          reading_tasks = non_nil_data.select { |dd| dd.type == 'reading' }.map(&:task)

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

    # Return reading, homework and external tasks for a student
    # reorder(nil) is required for distinct to work
    # distinct is required for preloading to work
    def get_course_tasks(course, role, is_teacher, current_time)
      is_teacher_student = role.present? && role.teacher_student?
      task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework, :external)
      tt = Tasks::Models::Task.arel_table
      er = Entity::Role.arel_table
      st = is_teacher_student ?
        CourseMembership::Models::TeacherStudent.arel_table :
        CourseMembership::Models::Student.arel_table
      up = User::Models::Profile.arel_table
      ac = OpenStax::Accounts::Account.arel_table
      rel = Tasks::Models::Task
        .select(
          [
            tt[ Arel.star ],
            er[:id].as('"role_id"'),
            is_teacher_student ? Arel::Nodes::SqlLiteral.new("'' as student_identifier") :
                                 st[:student_identifier],
            st[:course_membership_period_id],
            is_teacher_student ? st[:deleted_at].as('"dropped_at"') : st[:dropped_at],
            up[:id].as('"user_id"'),
            ac[:username],
            ac[:first_name],
            ac[:last_name]
          ]
        )
        .joins(:course, task_plan: :tasking_plans)
        .where(task_type: task_types,task_plan: { withdrawn_at: nil })
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

      if is_teacher
        rel = rel.joins(
          taskings: { role: [ :student, profile: :account ] }
        ).where(
          taskings: { role: { student: { course_profile_course_id: course.id } } }
        )
      elsif is_teacher_student
        rel = rel.joins(
          taskings: { role: [ :teacher_student, profile: :account ] }
        ).where(taskings: { role: role })
      else # treat as student and load only that role's tasks
        rel = rel.joins(
          taskings: { role: [ :student, profile: :account ] }
        ).where(taskings: { role: role })
      end

      rel.to_a
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

        late = tt.worked_on? && tt.due_at.present? && tt.last_worked_at > tt.due_at
        type = tt.task_type
        show_score = is_teacher || tt.feedback_available?(current_time: current_time)
        correct_exercise_count = show_score ? tt.correct_exercise_count : nil

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
          late:                                   late,
          status:                                 tt.status(use_cache: true),
          type:                                   type,
          id:                                     tt.id,
          due_at:                                 tt.due_at,
          last_worked_at:                         tt.last_worked_at&.in_time_zone(tz),
          is_extended:                            tt.extended?,
          is_past_due:                            tt.past_due?,
          step_count:                             tt.steps_count,
          completed_step_count:                   tt.completed_steps_count,
          completed_on_time_steps_count:          tt.completed_on_time_steps_count,
          actual_and_placeholder_exercise_count:  tt.actual_and_placeholder_exercise_count,
          completed_exercise_count:               tt.completed_exercise_count,
          completed_on_time_exercise_steps_count: tt.completed_on_time_exercise_steps_count,
          correct_exercise_count:                 correct_exercise_count,
          recovered_exercise_count:               tt.recovered_exercise_steps_count,
          gradable_step_count:                    tt.gradable_step_count,
          ungraded_step_count:                    tt.ungraded_step_count,
          is_included_in_averages:                included_in_progress_averages?(task: tt),
          available_points:                       available_points,
          progress:                               progress,
          published_points:                       published_points,
          published_score:                        published_score,
          is_provisional_score:                   tt.provisional_score?
        )
      end
    end
  end
end

module Tasks
  class GetPerformanceBook
    lev_routine express_output: :performance_book

    uses_routine Role::GetUsersForRoles,
                 as: :get_users_for_roles,
                 translations: { outputs: { type: :verbatim } }

    uses_routine UserProfile::GetUserFullNames,
                 as: :get_user_full_names,
                 translations: { outputs: { type: :verbatim } }

    uses_routine CourseMembership::GetStudents,
                 as: :get_students,
                 translations: { outputs: { type: :verbatim } }

    protected

    def exec(course:, role:)
      outputs[:performance_book] = \
        if CourseMembership::IsCourseTeacher[course: course, roles: [role]]
          get_performance_book_for_teacher(course)
        else
          raise(SecurityTransgression, 'The caller is not a teacher in this course')
        end
    end

    private

    def get_performance_book_for_teacher(course)
      student_data_list = []
      tasks = []

      run(:get_students, course).outputs.students.each do |student|
        tasks = get_tasks(student)
        @class_average = [[]] * tasks.count
        student_data_list << get_student_data(student, tasks)
      end

      {
        data_headings: tasks.collect.with_index { |t, i| get_data_headings(t, i) },
        students: student_data_list,
      }
    end

    def get_tasks(role)
      # Return reading and homework tasks for a student ordered by due date
      Tasks::Models::Task
        .joins { taskings }
        .where { taskings.entity_role_id == role.id }
        .where { task_type.in Tasks::Models::Task.task_types.values_at(:reading, :homework) }
        .order { due_at }
        .includes(:task_steps)
    end

    def get_data_headings(task, index)
      { title: task.title }.merge(class_average(task, index))
    end

    def class_average(task, index)
      # check if the task is a homework and at least one person has started on it
      return {} unless task.task_type == 'homework' && @class_average[index].present?
      {
        class_average: @class_average[index].reduce(:+) * 100 / @class_average[index].length
      }
    end

    def get_student_data(role, tasks)
      users = run(:get_users_for_roles, role).outputs.users

      {
        name: run(:get_user_full_names, users).outputs.full_names.first,
        role: role.id,
        data: tasks.collect.with_index { |t, i|
          data = {
            status: t.status,
            type: t.task_type,
            id: t.id,
          }

          if t.task_type == 'homework'
            data.merge!(exercise_count(t.task_steps, i))
          end

          data
        }
      }
    end

    def exercise_count(task_steps, index)
      attempted_count = task_steps.select(&:completed?).length
      tasked_ids = task_steps.collect(&:tasked_id).join(',')
      exercises = Models::TaskedExercise.find_by_sql("SELECT  * FROM tasks_tasked_exercises WHERE id IN (#{tasked_ids})")
      correct_count = exercises.select(&:is_correct?).length

      if attempted_count > 0
        @class_average[index] << (Float(correct_count) / attempted_count)
      end

      {
        exercise_count: task_steps.length,
        correct_exercise_count: correct_count,
        recovered_exercise_count: exercises.select(&:can_be_recovered?).length
      }
    end
  end
end

require_relative 'models/entity_extensions'

class Tasks::GetPerformanceBook
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
    @class_average = []
    tasks = []
    run(:get_students, course).outputs.students.each do |student|
      tasks = get_tasks_for_student(student)
      tasks.each { |task| @class_average << [] }
      users = run(:get_users_for_roles, student).outputs.users
      full_name = run(:get_user_full_names, users).outputs.full_names.first
      student_data_list << get_student_data(tasks, full_name, student)
    end

    performance_book = {
      data_headings: tasks.collect.with_index { |task, index| get_data_headings(task, index) },
      students: student_data_list,
    }
  end

  def get_tasks_for_student(student)
    # Return reading and homework tasks for a student ordered by due date
    Tasks::Models::Task
      .joins { taskings }
      .where { taskings.entity_role_id == student.id }
      .where { task_type.in Tasks::Models::Task.task_types.values_at(:reading, :homework) }
      .order { due_at }
  end

  def get_data_headings(task, index)
    { title: task.title }.merge(class_average(task, index))
  end

  def class_average(task, index)
    # Only return a class average if the task is a homework and at least one person has started on it
    return {} unless task.task_type == 'homework' && @class_average[index].present?
    { class_average: @class_average[index].reduce(:+) * 100 / @class_average[index].length }
  end

  def get_student_data(tasks, full_name, role)
    student_data = {
      name: full_name,
      role: role.id,
      data: [],
    }
    tasks.each_with_index do |task, index|
      data = {
        status: task_status(task),
        type: task.task_type,
        id: task.id,
      }
      data.merge!(exercise_count(task, index))
      student_data[:data] << data
    end
    student_data
  end

  def task_status(task)
    # task is "completed" if all steps are completed,
    #         "in_progress" if some steps are completed and
    #         "not_started" if no steps are completed
    if task.completed?
      'completed'
    else
      in_progress = task.task_steps.any? { |ts| ts.completed? }
      in_progress ? 'in_progress' : 'not_started'
    end
  end

  def exercise_count(task, index)
    return {} unless task.task_type == 'homework'
    correct_count = task.task_steps.select { |ts| ts.tasked.is_correct? }.length
    attempted_count = task.task_steps.select { |ts| ts.completed? }.length
    @class_average[index] << (Float(correct_count) / attempted_count) if attempted_count > 0
    {
      exercise_count: task.task_steps.length,
      correct_exercise_count: correct_count,
      recovered_exercise_count: task.task_steps.select { |ts| ts.tasked.can_be_recovered? }.length
    }
  end

end

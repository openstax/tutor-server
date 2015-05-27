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
    raise(SecurityTransgression, 'The caller is not a teacher in this course') \
      unless CourseMembership::IsCourseTeacher[course: course, roles: [role]]

    outputs[:performance_book] = get_performance_book_for_teacher(course)
  end

  private

  def get_performance_book_for_teacher(course)
    student_data_list = []
    @class_average = []
    tasks = []

    students = run(:get_students, course).outputs.students
    role_to_user_map = run(:get_users_for_roles, students).outputs.role_to_user_map
    # TODO get a user_to_full_name_map and build a student_full_name_map to use below
    # instead of calling that query over and over

    students.each do |student|
      tasks = get_tasks_for_student(student)
      tasks.count.times { @class_average << [] }
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
      .includes(task_steps: :tasked)
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
        status: task.status,
        type: task.task_type,
        id: task.id,
      }
      data.merge!(exercise_count(task, index))
      student_data[:data] << data
    end
    student_data
  end

  def exercise_count(task, index)
    return {} unless task.task_type == 'homework'

    exercise_task_steps = task.task_steps.exercises.includes(:tasked)

    correct_count = exercise_task_steps.select{ |s| s.is_correct? }.length
    attempted_count = exercise_task_steps.select(&:completed?).length
    @class_average[index] << (Float(correct_count) / attempted_count) if attempted_count > 0

    {
      exercise_count: exercise_task_steps.length,
      correct_exercise_count: correct_count,
      recovered_exercise_count: exercise_task_steps.select{ |ts| ts.tasked.can_be_recovered? }.length
    }
  end
end

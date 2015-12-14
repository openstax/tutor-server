module DashboardRoutineMethods
  def self.included(base)
    base.lev_routine outputs: { role: :_self,
                                course: :_self,
                                tasks: :_self },
                     uses: [{ name: ::Tasks::GetTasks, as: :get_tasks },
                            { name: GetCourseTeachers, as: :get_course_teachers },
                            { name: CourseMembership::IsCourseTeacher },
                            { name: CourseMembership::IsCourseStudent }]
  end

  protected

  def get_role_type(course, role)
    if CourseMembership::IsCourseTeacher.call(course: course, roles: role)
      :teacher
    elsif CourseMembership::IsCourseStudent.call(course: course, roles: role)
      :student
    end
  end

  def load_role(role, role_type)
    set(role: { id: role.id, type: role_type.to_s })
  end

  def load_course(course, role_type)
    teachers = run(:get_course_teachers, course).teachers

    set(course: { id: course.id, name: course.name, teachers: teachers })
  end

  def load_tasks(role, role_type)
    entity_tasks = run(:get_tasks, roles: role).tasks
    entity_tasks = entity_tasks.joins(:task).preload(:task)
    entity_tasks = entity_tasks.where{ task.opens_at < Time.now } if :student == role_type
    tasks = entity_tasks.map{ |entity_task| entity_task.task }
    set(tasks: tasks)
  end
end

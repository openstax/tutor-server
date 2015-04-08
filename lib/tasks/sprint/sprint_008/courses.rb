module Sprint008
  class Courses
    lev_routine

    protected

    def exec
      student, teacher, both_user = create_users
      taken, teaching, both_course = create_courses

      AddUserAsCourseTeacher.call(course: teaching, user: teacher)
      AddUserAsCourseStudent.call(course: taken, user: student)

      AddUserAsCourseTeacher.call(course: both_course, user: both_user)
      AddUserAsCourseStudent.call(course: both_course, user: both_user)

      taken_plan    = FactoryGirl.create( :tasks_task_plan, owner: taken)
      FactoryGirl.create(:tasks_task, tasked_to:[student], task_plan: taken_plan)

      teaching_plan = FactoryGirl.create( :tasks_task_plan, owner: teaching)
      FactoryGirl.create(:tasks_task, tasked_to:[student], task_plan: teaching_plan)

      both_plan     = FactoryGirl.create( :tasks_task_plan, owner: both_course)
      FactoryGirl.create(:tasks_task, tasked_to:[teacher], task_plan: both_plan)
      FactoryGirl.create(:tasks_task, tasked_to:[student], task_plan: both_plan)
    end

    private

    def create_users
      return FactoryGirl.create(:user, username: 'student'),
             FactoryGirl.create(:user, username: 'teacher'),
             FactoryGirl.create(:user, username: 'both')
    end

    def create_courses
      taken = CreateCourse.call(name: 'Being Taken').outputs.profile
      teaching = CreateCourse.call(name: 'Being Taught').outputs.profile
      both = CreateCourse.call(name: 'Both').outputs.profile
      return taken.course, teaching.course, both.course
    end

  end
end

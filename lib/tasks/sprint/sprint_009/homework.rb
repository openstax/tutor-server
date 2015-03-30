module Sprint009
  class Homework

    lev_routine

    protected

    def exec
      teacher = FactoryGirl.create :user, username: 'teacher'
      student = FactoryGirl.create :user, username: 'student'

      book = Domain::FetchAndImportBook.call(
               id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
             ).outputs.book
      course = Domain::CreateCourse.call.outputs.course
      Domain::AddBookToCourse.call(book: book, course: course)
      Domain::AddUserAsCourseTeacher.call(course: course, user: teacher)

      a = FactoryGirl.create :assistant, code_class_name: "HomeworkAssistant"
      tp = FactoryGirl.create :task_plan, assistant: a,
                                          settings: { exercise_ids: [
        1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25
      ] }
      tp.tasking_plans << FactoryGirl.create(:tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)

      tp = FactoryGirl.create :task_plan, assistant: a,
                                          settings: { exercise_ids: [
        2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24
      ] }
      tp.tasking_plans << FactoryGirl.create(:tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)

      tp = FactoryGirl.create :task_plan, assistant: a,
                                          settings: { exercise_ids: [
        1, 2, 3, 5, 8, 13, 21
      ] }
      tp.tasking_plans << FactoryGirl.create(:tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)
    end

  end
end

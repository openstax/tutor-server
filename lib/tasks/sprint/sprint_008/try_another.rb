module Sprint008
  class TryAnother

    lev_routine

    protected

    def exec
      teacher = FactoryGirl.create :user_profile, username: 'teacher'
      student = FactoryGirl.create :user_profile, username: 'student'

      book = Domain::FetchAndImportBook.call(
               id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
             ).outputs.book
      course = Domain::CreateCourse.call.outputs.course
      Domain::AddBookToCourse.call(book: book, course: course)
      Domain::AddUserAsCourseTeacher.call(course: course, user: teacher)

      a = FactoryGirl.create :tasks_assistant, code_class_name: "Tasks::Assistants::IReadingAssistant"
      page_ids = Content::Models::BookPart.where(book: book)
                 .first.child_book_parts.first.pages.pluck(:id)[0..1]
      tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          settings: { page_ids: page_ids }
      tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)

      tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          settings: { page_ids: [3] }
      tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)

      tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          settings: { page_ids: [4] }
      tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)
    end

  end
end

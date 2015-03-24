module Sprint008
  class PwReal

    lev_routine

    protected

    def exec
      user = FactoryGirl.create :user, username: 'student'
      course = Entity::Course.create!
      Domain::AddUserAsCourseStudent[course: course, user: user]
      student_role = Entity::Role.last

      book = Domain::FetchAndImportBook[id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58']
      Domain::AddBookToCourse[book: book, course: course]

      Domain::ResetPracticeWidget[role: student_role, page_ids: []]
    end

  end
end
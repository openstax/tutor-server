module Sprint008
  class PwReal

    lev_routine

    protected

    def exec

      OpenStax::BigLearn::V1.use_real_client

      user = FactoryGirl.create :user, username: 'student'
      course = Entity::Course.create!
      Domain::AddUserAsCourseStudent[course: course, user: user]
      student_role = Entity::Role.last

      outputs[:book_id] = '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'

      book = Domain::FetchAndImportBook[id: outputs[:book_id]]
      Domain::AddBookToCourse[book: book, course: course]

      condition = {
        _and: [
          {
            _or: [
              'practice-concepts',
              'practice-problem',
              'test-prep-multiple-choice'
            ]
          },
          {
            _or: [
              'k12phys-ch04-s01-lo01',
              'k12phys-ch04-s01-lo02'
            ]
          }
        ]
      }

      outputs[:task] = Domain::ResetPracticeWidget[
        role: student_role,
        condition: condition
      ]

      outputs[:course] = course
      outputs[:condition] = condition
    end

  end
end

module Sprint007
  class Main

    include WebMock::API

    lev_routine

    uses_routine OpenStax::Accounts::Dev::CreateAccount, 
                 as: :create_account,
                 translations: { outputs: {type: :verbatim} }

    protected

    def exec(username_or_user:)

      if username_or_user.is_a? String
        run(:create_account, username: username_or_user)
        legacy_user = UserMapper.account_to_user(outputs[:account])
      else
        legacy_user = username_or_user
      end

      book = Domain::ImportBook.call(cnx_id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58').outputs.book
      course = Domain::CreateCourse.call.outputs.course
      Domain::AddBookToCourse.call(book: book, course: course)
      user = LegacyUser::FindOrCreateUserForLegacyUser.call(legacy_user).outputs.user
      Domain::AddUserAsCourseTeacher.call(course: course, user: user)

      FactoryGirl.create(:assistant, code_class_name: "IReadingAssistant")

      outputs[:legacy_user] = legacy_user
      outputs[:course] = course
    end

  end
end
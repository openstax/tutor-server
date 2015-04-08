module Sprint008
  class Pw

    lev_routine

    protected

    def exec
      user = FactoryGirl.create :user, username: 'student'
      outputs[:course] = Entity::Course.create!
      AddUserAsCourseStudent.call(course: outputs[:course], user: user)
      outputs[:role] = Entity::Role.last
      ResetPracticeWidget.call(role: outputs[:role], condition: :fake)
    end

  end
end

require 'rails_helper'

describe "domain: course roles" do

  context "adding teachers to courses" do
    let(:target_user)   { EntitySs::CreateUser.call.outputs.user }
    let(:target_course) { EntitySs::CreateCourse.call.outputs.course }
    context "when a user is not a teacher of a course" do
      it "the user can be made a course teacher" do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty

        result = Domain::UserIsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy
      end
    end
    context "when the user is a teacher of a course" do
      before(:each) do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
      end
      it "the user cannot be (re)made a course teacher" do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to_not be_empty

        result = Domain::UserIsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy
      end
    end
    context "courses with multiple teachers" do
      let(:target_user1)  { EntitySs::CreateUser.call.outputs.user }
      let(:target_user2)  { EntitySs::CreateUser.call.outputs.user }
      let(:target_course) { EntitySs::CreateCourse.call.outputs.course }
      it "is allowed" do
        result = Domain::AddUserAsCourseTeacher.call(user: target_user1, course: target_course)
        expect(result.errors).to be_empty

        result = Domain::AddUserAsCourseTeacher.call(user: target_user2, course: target_course)
        expect(result.errors).to be_empty

        result = Domain::UserIsCourseTeacher.call(user: target_user1, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy

        result = Domain::UserIsCourseTeacher.call(user: target_user2, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_teacher).to be_truthy
      end
    end
  end

end

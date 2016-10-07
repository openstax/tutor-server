require 'rails_helper'

RSpec.describe UserIsCourseStudent, type: :routine do

  context "when the user is not a student for the given course" do
    it "returns false" do
      target_user         = FactoryGirl.create :user

      target_student_role = FactoryGirl.create :entity_role
      target_teacher_role = FactoryGirl.create :entity_role

      other_user          = FactoryGirl.create :user

      other_student_role  = FactoryGirl.create :entity_role

      target_course       = FactoryGirl.create :entity_course
      target_period       = FactoryGirl.create :course_membership_period, course: target_course

      other_course        = FactoryGirl.create :entity_course
      other_period        = FactoryGirl.create :course_membership_period, course: other_course

      Role::AddUserRole.call(user: target_user, role: target_student_role)
      Role::AddUserRole.call(user: target_user, role: target_teacher_role)
      Role::AddUserRole.call(user: other_user,  role: other_student_role)

      ## Make the target user a student of another course
      CourseMembership::AddStudent.call(period: other_period, role: target_student_role)
      ## Make the target user a teacher in the target course
      CourseMembership::AddTeacher.call(course: other_course, role: target_teacher_role)
      ## Make another user a student of the target course
      CourseMembership::AddStudent.call(period: target_period, role: other_student_role)

      ## Perform test
      result = UserIsCourseStudent.call(user: target_user, course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.user_is_course_teacher).to be_falsey
    end
  end

  context "when the user is a student for the given course" do
    let(:target_user)         { FactoryGirl.create(:user) }
    let(:target_student_role) { FactoryGirl.create :entity_role }

    let(:target_course) { FactoryGirl.create :entity_course }
    let(:target_period) { FactoryGirl.create :course_membership_period, course: target_course }

    before {
      Role::AddUserRole.call(user: target_user, role: target_student_role)
      CourseMembership::AddStudent.call(period: target_period, role: target_student_role)
    }

    it "returns true" do
      result = UserIsCourseStudent.call(user: target_user, course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.user_is_course_student).to be_truthy
    end
    context "and period is archived" do
      before {
        target_period.to_model.destroy
      }
      it "returns false" do
        result = UserIsCourseStudent.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_student).to be_falsey
      end
    end

    context "and is also a member of a non-archived period" do
      let(:new_period)       { FactoryGirl.create :course_membership_period, course: target_course }
      let(:new_student_role) { FactoryGirl.create :entity_role }
      before {
        Role::AddUserRole.call(user: target_user, role: new_student_role)
        CourseMembership::AddStudent.call(period: new_period, role: new_student_role)
      }
      it "returns true" do
        result = UserIsCourseStudent.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.user_is_course_student).to be_truthy
      end
    end

  end
end

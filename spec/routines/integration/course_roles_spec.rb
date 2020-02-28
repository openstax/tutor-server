require 'rails_helper'

RSpec.describe "domain: course roles", type: :integration do

  context "adding teachers to courses" do
    let(:target_user)   { FactoryBot.create(:user_profile) }
    let(:target_course) { FactoryBot.create :course_profile_course }

    context "when a user is not a teacher of a course" do
      it "the user can be made a course teacher" do
        result = AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty

        result = UserIsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
    context "when the user is a teacher of a course" do
      before(:each) do
        result = AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
      end
      it "the user cannot be (re)made a course teacher" do
        result = AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to_not be_empty

        result = UserIsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
    context "courses with multiple teachers" do
      let(:target_user1)  { FactoryBot.create(:user_profile) }
      let(:target_user2)  { FactoryBot.create(:user_profile) }
      let(:target_course) { FactoryBot.create :course_profile_course }

      it "are allowed" do
        result = AddUserAsCourseTeacher.call(user: target_user1, course: target_course)
        expect(result.errors).to be_empty

        result = AddUserAsCourseTeacher.call(user: target_user2, course: target_course)
        expect(result.errors).to be_empty

        result = UserIsCourseTeacher.call(user: target_user1, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy

        result = UserIsCourseTeacher.call(user: target_user2, course: target_course)
        expect(result.errors).to be_empty
        expect(result.outputs.is_course_teacher).to be_truthy
      end
    end
  end

  context "adding students to courses" do
    let(:target_user)   { FactoryBot.create :user_profile }
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:target_period) { FactoryBot.create :course_membership_period, course: target_course }

    context "when a user is not a teacher of a course" do
      context "and the user is not a student in the course" do
        it "the user can be added as a course student" do
          result = AddUserAsPeriodStudent.call(user: target_user, period: target_period)
          expect(result.errors).to be_empty

          result = UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.is_course_student).to be_truthy
        end
      end
      context "and the user is already a student in the course" do
        before(:each) do
          result = AddUserAsPeriodStudent.call(user: target_user, period: target_period)
          expect(result.errors).to be_empty
        end
        it "the user cannot be (re)added as a course student" do
          result = AddUserAsPeriodStudent.call(user: target_user, period: target_period)
          expect(result.errors).to_not be_empty

          result = UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.is_course_student).to be_truthy
        end
      end
    end
    context "when a user is a teacher of a course" do
      before(:each) do
        result = AddUserAsCourseTeacher.call(user: target_user, course: target_course)
        expect(result.errors).to be_empty
      end
      context "and the user is not already a student in the course" do
        it "the user can be added as a course student" do
          result = AddUserAsPeriodStudent.call(user: target_user, period: target_period)
          expect(result.errors).to be_empty

          result = UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.is_course_student).to be_truthy
        end
      end
      context "and the user is already a student in the course" do
        before(:each) do
          result = AddUserAsPeriodStudent.call(user: target_user, period: target_period)
          expect(result.errors).to be_empty
          @previous_student_role = result.outputs.role
          expect(@previous_student_role).to_not be_nil
        end
        let(:previous_student_role) { @previous_student_role }

        it "the user can be added as a course student" do
          result = AddUserAsPeriodStudent.call(user: target_user, period: target_period)
          expect(result.errors).to be_empty
          expect(result.outputs.role).to_not be_nil
          expect(result.outputs.role).to_not eq(previous_student_role)

          result = UserIsCourseStudent.call(user: target_user, course: target_course)
          expect(result.errors).to be_empty
          expect(result.outputs.is_course_student).to be_truthy
        end
      end
    end
  end
end

require 'rails_helper'

describe AddUserAsPeriodStudent, type: :routine do
  context "when the given user is not a teacher of the course" do
    let(:user)   { FactoryGirl.create(:user) }
    let(:course) { Entity::Course.create! }
    let(:period) { CreatePeriod[course: course] }

    context "and not already a student of the course" do
      it "succeeds and returns the user's new student role" do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
      end

      it "allows a student_identifier to be specified" do
        sid = 'N0B0DY'
        result = AddUserAsPeriodStudent.call(user: user, period: period, student_identifier: sid)
        expect(result.errors).to be_empty
        expect(result.outputs.role.student.student_identifier).to eq sid
      end
    end

    context "and already a student in the given course" do
      before(:each) do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
      end
      it "has errors" do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to_not be_empty
      end
    end

    context "and is a previously dropped student" do
      before(:each) do
        student = AddUserAsPeriodStudent.call(user: user, period: period)
                  .outputs.student
        student.destroy
      end
      it "has inactive student error" do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to_not be_empty
        expect(result.errors.map(&:code).first).to be :user_is_an_inactive_student
      end
    end

    context "and the period is archived" do
      before(:each) do
        AddUserAsPeriodStudent.call(user: user, period: period)
        period.to_model.destroy
      end
      fit "has inactive student error" do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to_not be_empty
        expect(result.errors.map(&:code).first).to be :user_is_an_inactive_student
      end
    end
  end

  context "when the given user is a teacher in the given course" do
    let(:user)   { FactoryGirl.create(:user) }
    let(:course) { Entity::Course.create! }
    let(:period) { CreatePeriod[course: course] }

    before(:each) do
      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil
    end

    context "and not already a student of the course" do
      it "succeeds and returns the user's new student role" do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
      end
    end

    context "and already a student in the given course" do
      before(:each) do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to be_empty
        @previous_student_role = result.outputs.role
        expect(@previous_student_role).to_not be_nil
      end

      let(:previous_student_role) { @previous_student_role }

      it "succeeds and returns the user's new student role" do
        result = AddUserAsPeriodStudent.call(user: user, period: period)
        expect(result.errors).to be_empty
        expect(result.outputs.role).to_not be_nil
        expect(result.outputs.role).to_not eq(previous_student_role)
      end
    end
  end
end

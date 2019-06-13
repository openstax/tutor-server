require 'rails_helper'

RSpec.describe ChooseCourseRole, type: :routine do

  let(:teacher)    { FactoryBot.create :user }
  let(:student)    { FactoryBot.create :user }
  let(:interloper) { FactoryBot.create :user }
  let(:course)     { FactoryBot.create :course_profile_course }
  let(:period)     { FactoryBot.create :course_membership_period, course: course }

  let!(:teacher_role)         { AddUserAsCourseTeacher[user: teacher, course: course] }
  let!(:student_role)         { AddUserAsPeriodStudent[user: student, period: period] }
  let!(:teacher_student_role) do
    FactoryBot.create(:course_membership_teacher_student, period: period).role
  end

  context "when the user is both a teacher and a student" do
    let(:user) { FactoryBot.create(:user) }
    let!(:user_teacher_role) { AddUserAsCourseTeacher[user: user, course: course] }
    let!(:user_student_role) { AddUserAsPeriodStudent[user: user, period: period] }

    context "and a role is not given" do
      context "and allowed_role_types is not given" do
        subject do
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            current_roles_hash: {}
          )
        end

        it "returns the user's teacher role" do
          expect(subject.outputs.role).to eq(user_teacher_role)
        end
      end

      context "and allowed_role_types: :teacher" do
        subject do
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            current_roles_hash: {},
            allowed_role_types: :teacher
          )
        end

        it "returns the user's teacher role" do
          expect(subject.outputs.role).to eq(user_teacher_role)
        end
      end

      context "and allowed_role_types: :student" do
        subject do
          ChooseCourseRole.call(
            user:    user,
            course:  course,
            current_roles_hash: {},
            allowed_role_types: :student
          )
        end

        it "returns the user's student role" do
          expect(subject.outputs.role).to eq(user_student_role)
        end
      end
    end
  end

  context "when a current role is provided" do
    let(:allowed_role_types) { [ :teacher, :student, :teacher_student ] }
    subject(:result) do
      ChooseCourseRole.call(
        user: student, course: course,
        current_roles_hash: current_roles_hash, allowed_role_types: allowed_role_types
      )
    end

    context "and the user has it" do
      let(:current_roles_hash) { { course.id.to_s => student_role.id } }

      it "returns the user's role" do
        expect(subject.outputs.role).to eq(student_role)
      end
    end

    context "and the user lacks it but has a different role of the chosen type" do
      let(:current_roles_hash) { { course.id.to_s => teacher_role.id } }

      it "ignores the role provided and returns one of the user's valid roles" do
        expect(subject.outputs.role).to eq(student_role)
      end
    end

    context "and the user lacks it and has no other roles of the chosen type" do
      let(:current_roles_hash) { { course.id.to_s => teacher_role.id } }
      let(:allowed_role_types) { [ :teacher ] }

      context "errors" do
        subject { result.errors }

        it { should_not be_empty }

        it { expect(subject.first.code).to eq(:user_not_in_course_with_required_role) }
      end

      context "output" do
        subject { result.outputs.role }

        it { should be_nil }
      end
    end
  end

  context "when a role is not given" do
    let(:allowed_role_types) { [ :teacher, :student, :teacher_student ] }
    subject(:result) do
      ChooseCourseRole.call(user: user, course: course,
                            current_roles_hash: {}, allowed_role_types: allowed_role_types)
    end

    context "and the user does not have any roles on the course" do
      let(:user) { interloper }

      context "errors" do
        subject { result.errors }

        it { should_not be_empty }

        it { expect(subject.first.code).to eq(:user_not_in_course_with_required_role) }
      end

      context "output" do
        subject { result.outputs.role }

        it { should be_nil }
      end
    end

    context "and the user has a single role" do
      let(:user) { teacher }

      context "errors" do
        subject { result.errors }
        it { should be_empty }
      end

      context "output" do
        subject { result.outputs.role }

        it { should eq(teacher_role) }
      end
    end

    context "and the user has a multiple roles" do
      let!(:student_role_1) { AddUserAsPeriodStudent[user: teacher, period: period] }
      let!(:student_role_2) do
        # Bypass AddUserAsPeriodStudent's error checking
        role = FactoryBot.create :entity_role, profile: teacher.to_model, role_type: :student
        CourseMembership::AddStudent[period: period, role: role]
      end
      let(:user) { teacher }

      it "returns the oldest role" do
        expect(result.outputs.role).to eq(teacher_role)
      end

      context "and a student role is requested" do
        let(:allowed_role_types) { :student }

        it "returns the oldest student role" do
          expect(result.outputs.role).to eq student_role_1
        end
      end
    end
  end
end

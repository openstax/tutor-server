require 'rails_helper'

RSpec.describe CourseMembership::GetCourseRoles, type: :routine do
  let(:target_course) { FactoryBot.create :course_profile_course }
  let(:target_period) { FactoryBot.create :course_membership_period, course: target_course }

  let(:other_course) { FactoryBot.create :course_profile_course }
  let(:other_period) { FactoryBot.create :course_membership_period, course: other_course }

  let!(:other_student_role) do
    other_role = FactoryBot.create :entity_role
    CourseMembership::AddStudent.call(
      period: other_period,
      role:   other_role
    )
    other_role
  end

  let!(:other_teacher_role) do
    other_role = FactoryBot.create :entity_role
    CourseMembership::AddTeacher.call(
      course: other_course,
      role:   other_role
    )
    other_role
  end

  context "when an invalid :type is used" do
    let(:types) { :bogus_type }
    let!(:student_role) do
      target_role = FactoryBot.create :entity_role
      CourseMembership::AddStudent.call(
        period: target_period,
        role:   target_role
      )
      target_role
    end
    let!(:teacher_role) do
      target_role = FactoryBot.create :entity_role
      CourseMembership::AddTeacher.call(
        course: target_course,
        role:   target_role
      )
      target_role
    end

    it "returns an empty enumerable" do
      result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
      expect(result.errors).to be_empty
      expect(result.outputs.roles).to be_empty
    end
  end

  context "when types: :any" do
    let(:types) { :any }

    context "and there are no periods for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end

      context "and there is one teacher role for the target course" do
        let!(:target_teacher_role) do
          target_role = FactoryBot.create :entity_role
          CourseMembership::AddTeacher.call(
            course: target_course,
            role:   target_role
          )
          target_role
        end

        it "returns an enumerable containing that role" do
          result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
          expect(result.errors).to be_empty
          expect(result.outputs.roles.count).to eq(1)
          expect(result.outputs.roles).to include(target_teacher_role)
        end
      end
    end

    context "and there is one period for the target course" do
      before { target_period }

      context "with no students" do
        it "returns an empty enumerable" do
          result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
          expect(result.errors).to be_empty
          expect(result.outputs.roles).to be_empty
        end

        context "and one teacher_student role" do
          let!(:target_teacher_student_role) do
            FactoryBot.create(:course_membership_teacher_student, period: target_period).role
          end

          it "returns an enumerable containing the teacher_student role" do
            result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
            expect(result.outputs.roles.count).to eq(1)
            expect(result.outputs.roles).to include(target_teacher_student_role)
          end
        end
      end

      context "with one student" do
        let!(:target_student_role) do
          target_role = FactoryBot.create :entity_role
          CourseMembership::AddStudent.call(
            period: target_period,
            role:   target_role
          )
          target_role
        end

        it "returns an enumerable containing that role" do
          result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
          expect(result.errors).to be_empty
          expect(result.outputs.roles.count).to eq(1)
          expect(result.outputs.roles).to include(target_student_role)
        end

        context "and one teacher_student role" do
          let!(:target_teacher_student_role) do
            FactoryBot.create(:course_membership_teacher_student, period: target_period).role
          end

          it "returns an enumerable containing that role and the teacher_student role" do
            result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
            expect(result.errors).to be_empty
            expect(result.outputs.roles.count).to eq(2)
            expect(result.outputs.roles).to include(target_student_role)
            expect(result.outputs.roles).to include(target_teacher_student_role)
          end
        end
      end

      context "and there are multiple teacher/student roles for the target course" do
        let!(:target_roles) do
          target_role1 = FactoryBot.create :entity_role
          CourseMembership::AddTeacher.call(
            course: target_course,
            role:   target_role1
          )

          target_role2 = FactoryBot.create :entity_role
          CourseMembership::AddStudent.call(
            period: target_period,
            role:   target_role2
          )

          target_role3 = FactoryBot.create :entity_role
          CourseMembership::AddStudent.call(
            period: target_period,
            role:   target_role3
          )
          [target_role1, target_role2, target_role3]
        end

        it "returns an enumerable containing those roles" do
          result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
          expect(result.errors).to be_empty
          expect(result.outputs.roles.count).to eq(target_roles.count)
          target_roles.each do |target_role|
            expect(result.outputs.roles).to include(target_role)
          end
        end

        context "and one teacher_student role" do
          let!(:target_teacher_student_role) do
            FactoryBot.create(:course_membership_teacher_student, period: target_period).role
          end

          it "returns an enumerable containing those roles and the teacher_student role" do
            result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
            expect(result.errors).to be_empty
            expect(result.outputs.roles.count).to eq(target_roles.count + 1)
            target_roles.each do |target_role|
              expect(result.outputs.roles).to include(target_role)
            end
            expect(result.outputs.roles).to include(target_teacher_student_role)
          end
        end
      end
    end
  end

  context "when types: :teacher" do
    let(:types) { :teacher }

    context "and there are no roles for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one student role for the target course" do
      let!(:target_student_role) do
        target_role = FactoryBot.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role
        )
        target_role
      end

      let!(:target_teacher_student_role) do
        FactoryBot.create(:course_membership_teacher_student, period: target_period).role
      end

      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one teacher role for the target course" do
      let!(:target_teacher_role) do
        target_role = FactoryBot.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role
        )
        target_role
      end

      let!(:target_teacher_student_role) do
        FactoryBot.create(:course_membership_teacher_student, period: target_period).role
      end

      it "returns an enumerable containing that role" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(1)
        expect(result.outputs.roles).to include(target_teacher_role)
      end
    end

    context "and there are multiple teacher/student roles for the target course" do
      let!(:target_roles) do
        target_role1 = FactoryBot.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role1
        )

        target_role2 = FactoryBot.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role2
        )

        target_role3 = FactoryBot.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role3
        )
        [target_role2]
      end

      let!(:target_teacher_student_role) do
        FactoryBot.create(:course_membership_teacher_student, period: target_period).role
      end

      it "returns an enumerable containing only the teacher roles" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(target_roles.count)
        target_roles.each do |target_role|
          expect(result.outputs.roles).to include(target_role)
        end
      end
    end
  end

  context "when types: :student" do
    let(:types)         { :student }
    let(:target_course) { FactoryBot.create :course_profile_course }
    let(:target_period) { FactoryBot.create :course_membership_period, course: target_course }

    context "and there are no roles for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one student role for the target course" do
      let!(:target_student_role) do
        target_role = FactoryBot.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role
        )
        target_role
      end

      let!(:target_teacher_student_role) do
        FactoryBot.create(:course_membership_teacher_student, period: target_period).role
      end

      it "returns an enumerable containing that role" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(1)
        expect(result.outputs.roles).to include(target_student_role)
      end
    end

    context "and there is one teacher role for the target course" do
      let!(:target_teacher_role) do
        target_role = FactoryBot.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role
        )
        target_role
      end

      let!(:target_teacher_student_role) do
        FactoryBot.create(:course_membership_teacher_student, period: target_period).role
      end

      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there are multiple teacher/student roles for the target course" do
      let!(:target_roles) do
        target_role1 = FactoryBot.create :entity_role
        CourseMembership::AddTeacher.call(
          course: target_course,
          role:   target_role1
        )

        target_role2 = FactoryBot.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role2
        )

        target_role3 = FactoryBot.create :entity_role
        CourseMembership::AddStudent.call(
          period: target_period,
          role:   target_role3
        )
        [target_role2, target_role3]
      end

      let!(:target_teacher_student_role) do
        FactoryBot.create(:course_membership_teacher_student, period: target_period).role
      end

      it "returns an enumerable containing only the student roles" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles.count).to eq(target_roles.count)
        target_roles.each do |target_role|
          expect(result.outputs.roles).to include(target_role)
        end
      end
    end
  end

  context "when types: :teacher_student" do
    let(:types) { :teacher_student }

    context "and there are no periods for the target course" do
      it "returns an empty enumerable" do
        result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
        expect(result.errors).to be_empty
        expect(result.outputs.roles).to be_empty
      end
    end

    context "and there is one period for the target course" do
      before { target_period }

      context "with no teacher_students" do
        it "returns an empty enumerable" do
          result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
          expect(result.errors).to be_empty
          expect(result.outputs.roles).to be_empty
        end
      end

      context "with a teacher_student role" do
        let!(:target_teacher_student_role) do
          FactoryBot.create(:course_membership_teacher_student, period: target_period).role
        end

        context "with no students" do
          it "returns an enumerable containing the teacher_student role" do
            result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
            expect(result.errors).to be_empty
            expect(result.outputs.roles.count).to eq(1)
            expect(result.outputs.roles).to include(target_teacher_student_role)
          end
        end

        context "and there are multiple teacher/student roles for the target course" do
          let!(:target_roles) do
            target_role1 = FactoryBot.create :entity_role
            CourseMembership::AddTeacher.call(
              course: target_course,
              role:   target_role1
            )

            target_role2 = FactoryBot.create :entity_role
            CourseMembership::AddStudent.call(
              period: target_period,
              role:   target_role2
            )

            target_role3 = FactoryBot.create :entity_role
            CourseMembership::AddStudent.call(
              period: target_period,
              role:   target_role3
            )
            [target_role1, target_role2, target_role3]
          end

          it "returns an enumerable containing only the teacher_student role" do
            result = CourseMembership::GetCourseRoles.call(course: target_course, types: types)
            expect(result.errors).to be_empty
            expect(result.outputs.roles.count).to eq(1)
            expect(result.outputs.roles).to include(target_teacher_student_role)
          end
        end
      end
    end
  end

end

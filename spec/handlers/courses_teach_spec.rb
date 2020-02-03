require 'rails_helper'

RSpec.describe CoursesTeach, type: :handler do
  let(:user)       { FactoryBot.create :user_profile }
  let(:course)     { FactoryBot.create :course_profile_course }
  subject(:result) { described_class.handle(caller: user, params: { teach_token: teach_token }) }

  context 'valid teach token' do
    let(:teach_token) { course.teach_token }

    context 'user is not in the course' do
      it 'adds the user as a course teacher' do
        expect { result }.to  change { CourseMembership::Models::Teacher.count }.by(1)
                         .and change { Entity::Role.count }.by(1)

        role = result.outputs.role
        teacher = result.outputs.teacher
        expect(role.profile).to eq user
        expect(role.teacher).to eq teacher
        expect(teacher.course).to eq course
      end
    end

    context 'user is already a course teacher' do
      before { AddUserAsCourseTeacher[user: user, course: course] }

      it 'does nothing' do
        expect { result }.to  not_change { CourseMembership::Models::Teacher.count }
                         .and not_change { Entity::Role.count }
      end
    end

    context 'user is already a course student' do
      let(:period) { FactoryBot.create :course_membership_period, course: course }
      before       { AddUserAsPeriodStudent[user: user, period: period] }

      it 'raises an exception' do
        expect { result }.to  not_change { CourseMembership::Models::Teacher.count }
                         .and not_change { Entity::Role.count }
                         .and raise_error(CoursesTeach::UserIsStudent)
      end
    end
  end

  context 'invalid teach token' do
    let(:teach_token) { SecureRandom.hex }

    it 'raises an exception' do
      expect { result }.to  not_change { CourseMembership::Models::Teacher.count }
                       .and not_change { Entity::Role.count }
                       .and raise_error(CoursesTeach::InvalidTeachToken)
    end
  end
end

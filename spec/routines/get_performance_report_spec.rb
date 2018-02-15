require 'rails_helper'

RSpec.describe GetPerformanceReport, type: :routine do

  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  context 'student role' do
    let(:user) { FactoryBot.create :user }
    let(:role) { AddUserAsPeriodStudent[user: user, period: period] }

    context 'non-cc course' do
      it 'calls GetTpPerformanceReport' do
        expect_any_instance_of(Tasks::GetTpPerformanceReport).to(
          receive(:exec).with(course: course, role: role)
        )

        described_class[course: course, role: role]
      end
    end

    context 'cc course' do
      before(:each) { course.update_attribute(:is_concept_coach, true) }

      it 'calls GetCcPerformanceReport' do
        expect_any_instance_of(Tasks::GetCcPerformanceReport).to(
          receive(:exec).with(course: course, role: role)
        )

        described_class[course: course, role: role]
      end
    end
  end

  context 'teacher role' do
    let(:user) { FactoryBot.create :user }
    let(:role) { AddUserAsCourseTeacher[user: FactoryBot.create(:user), course: course] }

    context 'non-cc course' do
      it 'calls GetTpPerformanceReport' do
        expect_any_instance_of(Tasks::GetTpPerformanceReport).to(
          receive(:exec).with(course: course, role: role)
        )

        described_class[course: course, role: role]
      end
    end

    context 'cc course' do
      before(:each) { course.update_attribute(:is_concept_coach, true) }

      it 'calls GetCcPerformanceReport' do
        expect_any_instance_of(Tasks::GetCcPerformanceReport).to(
          receive(:exec).with(course: course, role: role)
        )

        described_class[course: course, role: role]
      end
    end
  end

end

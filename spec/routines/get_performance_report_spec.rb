require 'rails_helper'

RSpec.describe GetPerformanceReport, type: :routine do

  let(:course) { CreateCourse[name: 'Physics'] }

  context 'non-teacher role' do
    let(:role) { Entity::Role.create! }

    it 'raises SecurityTransgression' do
      expect{ described_class[course: course, role: role] }.to raise_error(SecurityTransgression)
    end
  end

  context 'teacher role' do
    let(:user) { FactoryGirl.create :user }
    let(:role) { AddUserAsCourseTeacher[user: FactoryGirl.create(:user), course: course] }

    context 'non-cc course' do
      it 'calls GetTpPerformanceReport' do
        expect_any_instance_of(Tasks::GetTpPerformanceReport).to(
          receive(:exec).with(course: course)
        )

        described_class[course: course, role: role]
      end
    end

    context 'cc course' do
      before(:each) { course.profile.update_attribute(:is_concept_coach, true) }

      it 'calls GetCcPerformanceReport' do
        expect_any_instance_of(Tasks::GetCcPerformanceReport).to(
          receive(:exec).with(course: course)
        )

        described_class[course: course, role: role]
      end
    end
  end

end

require 'rails_helper'

RSpec.describe GetPerformanceReport, type: :routine do

  let(:course) { FactoryBot.create :course_profile_course }

  context 'non-teacher role' do
    let(:role) { FactoryBot.create :entity_role }

    it 'raises SecurityTransgression' do
      expect{ described_class[course: course, role: role] }.to raise_error(SecurityTransgression)
    end
  end

  context 'teacher role' do
    let(:user) { FactoryBot.create :user }
    let(:role) { AddUserAsCourseTeacher[user: FactoryBot.create(:user), course: course] }

    it 'calls GetPerformanceReport' do
      expect_any_instance_of(Tasks::GetPerformanceReport).to receive(:exec).with(course: course)

      described_class[course: course, role: role]
    end
  end

end

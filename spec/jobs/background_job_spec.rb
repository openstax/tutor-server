require 'rails_helper'

RSpec.describe Lev::BackgroundJob do
  it 'expires the jobs from the queue after a week' do
    user = FactoryGirl.create(:user_profile).entity_user
    course = CreateCourse[name: 'Test course']
    role = AddUserAsCourseTeacher[user: user, course: course]
    job_id = Tasks::ExportPerformanceReport.perform_later(role: role, course: course)

    job = described_class.find(job_id)

    expect(job.status).to eq(described_class::STATE_COMPLETED)

    Timecop.freeze(1.week.from_now) do
      job = described_class.find(job_id)
      expect(job.status).to eq(described_class::STATE_UNKNOWN)
    end
  end
end

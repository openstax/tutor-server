require 'rails_helper'

RSpec.describe Tasks::Jobs::ExportPerformanceReportJob do
  it 'executes the Tasks::ExportPerformanceReport routine' do
    course = Entity::Course.create!
    role = Entity::Role.create!

    allow(Tasks::ExportPerformanceReport).to receive(:[])

    job = described_class.new
    job.perform(role: role, course: course)

    expect(Tasks::ExportPerformanceReport).to have_received(:[])
      .with(course: course, role: role)
  end
end

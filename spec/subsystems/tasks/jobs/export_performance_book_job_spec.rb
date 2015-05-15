require 'rails_helper'

RSpec.describe Tasks::Jobs::ExportPerformanceBookJob do
  it 'executes the Tasks::ExportPerformanceBook routine' do
    course = Entity::Course.create!
    role = Entity::Role.create!

    allow(Tasks::ExportPerformanceBook).to receive(:[])

    job = described_class.new
    job.perform(role: role, course: course)

    expect(Tasks::ExportPerformanceBook).to have_received(:[])
      .with(course: course, role: role)
  end
end

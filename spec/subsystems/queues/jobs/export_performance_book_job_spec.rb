require 'rails_helper'

RSpec.describe Queues::Jobs::ExportPerformanceBookJob do
  let(:job) { described_class.new }
  let(:user) { Entity::User.create! }
  let(:course) { Entity::Course.last }
  let(:role) { Entity::Role.last }

  before do
    CreateCourse[name: 'Physics']
    AddUserAsCourseTeacher[course: course, user: user]
  end

  it 'creates an xlsx with a worksheet that has a course summary' do
    pending
    job.perform(role: role, course: course)

    export = Tasks::Models::PerformanceBookExport.last
    file = File.open(export.filepath)
  end
end

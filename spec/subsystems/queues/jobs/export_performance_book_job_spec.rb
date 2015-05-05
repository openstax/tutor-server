require 'rails_helper'

RSpec.describe Queues::Jobs::ExportPerformanceBookJob do
  it 'creates an xlsx with a worksheet that has a course summary' do
    job = described_class.new
    user = Entity::User.create!
    course = Entity::Course.create!
    AddUserAsCourseTeacher[course: course, user: user]
    role = Entity::Role.last

    job.perform(role: role, course: course)
    export = Tasks::Models::PerformanceBookExport.last
    file = File.open(export.filepath)
    binding.pry
  end
end

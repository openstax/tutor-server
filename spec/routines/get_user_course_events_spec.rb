require 'rails_helper'

RSpec.describe GetUserCourseEvents, :type => :routine do
  let(:course) { Domain::CreateCourse.call.outputs.course }
  let(:user)   { FactoryGirl.create(:user) }

  it 'gets all events for a course' do
    3.times{ FactoryGirl.create :tasks_task_plan, owner: course }
    3.times{ FactoryGirl.create(:tasking, taskee: user) }
    role = Entity::CreateRole.call.outputs.role
    Role::AddUserRole.call(user:user,role:role)
    CourseMembership::AddTeacher.call(course: course, role: role)

    out = GetUserCourseEvents.call(course: course, user:user).outputs

    expect(out.plans.length).to eq 3
    expect(out.tasks.length).to eq 3
  end

end

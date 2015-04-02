require 'rails_helper'

RSpec.describe GetUserCourseEvents, :type => :routine do
  let(:course) { Domain::CreateCourse.call.outputs.course }
  let(:user)   { FactoryGirl.create(:user_profile).entity_user }

  it 'gets all events for a course' do
    role = Entity::Role.create!
    Role::AddUserRole.call(user: user, role: role)

    3.times{ FactoryGirl.create :tasks_task_plan, owner: course }
    3.times{
      task = FactoryGirl.create(:tasks_task)
      FactoryGirl.create(:tasks_tasking, task: task.entity_task, role: role)
    }

    CourseMembership::AddTeacher.call(course: course, role: role)

    out = GetUserCourseEvents.call(course: course, user: user).outputs

    expect(out.plans.length).to eq 3
    expect(out.tasks.length).to eq 3
  end

end

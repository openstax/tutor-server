require 'rails_helper'

RSpec.describe Api::V1::CourseEventsRepresenter, :type => :representer do

  let(:course) { Domain::CreateCourse.call.outputs.course }
  let(:user)   { FactoryGirl.create(:user) }

  it 'gets all events for a course' do
    plan = FactoryGirl.create( :tasks_task_plan, owner: course)
    task = FactoryGirl.create( :tasks_task )

    role = Entity::CreateRole.call.outputs.role
    Role::AddUserRole.call(user:user,role:role)
    CourseMembership::AddTeacher.call(course: course, role: role)

    tasking = FactoryGirl.create(:tasks_tasking, role: role, task: task.entity_task)

    output = GetUserCourseEvents.call(course: course, user: user).outputs
    representation = Api::V1::CourseEventsRepresenter.new(output).as_json

    expect(representation).to include(
      "plans" => a_collection_including(
        a_hash_including(
          "id"       => plan.id,
          "opens_at" => DateTimeUtilities.to_api_s(plan.opens_at),
          "due_at"   => DateTimeUtilities.to_api_s(plan.due_at),
          "trouble"  => be_a_kind_of(TrueClass).or( be_a_kind_of(FalseClass) ),
          "type"     => plan.type
        )
      ),
      "tasks" => a_collection_including(
        a_hash_including(
          "id" => task.id,
          "opens_at" => DateTimeUtilities.to_api_s(task.opens_at),
          "due_at"   => DateTimeUtilities.to_api_s(task.due_at),
          "type"     => task.task_type,
          "complete" => task.completed?
        )
      )
    )

  end

end

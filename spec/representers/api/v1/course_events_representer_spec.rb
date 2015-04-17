require 'rails_helper'

RSpec.describe Api::V1::CourseEventsRepresenter, :type => :representer do

  let!(:course) { CreateCourse.call.outputs.course }
  let!(:plan1)   { FactoryGirl.create(:tasks_task_plan, owner: course) }
  let!(:plan2)   { FactoryGirl.create(:tasks_task_plan, owner: course) }
  let!(:task1)   { FactoryGirl.create(:tasks_task) }
  let!(:task2)   { FactoryGirl.create(:tasks_task) }

  it 'represents task plans and tasks' do
    represented = Hashie::Mash.new(
      tasks: [task1, task2],
      plans: [plan1, plan2]
    )

    representation = Api::V1::CourseEventsRepresenter.new(represented).as_json

    expect(representation).to include(
      "plans" => a_collection_including(
        plan_hash_including_for(plan: plan1),
        plan_hash_including_for(plan: plan2)
      ),
      "tasks" => a_collection_including(
        task_hash_including_for(task: task1),
        task_hash_including_for(task: task2)
      )
    )

  end

end

def plan_hash_including_for(plan:)
  a_hash_including(
    "id"       => plan.id,
    "opens_at" => DateTimeUtilities.to_api_s(plan.opens_at),
    "due_at"   => DateTimeUtilities.to_api_s(plan.due_at),
    "trouble"  => be_a_kind_of(TrueClass).or( be_a_kind_of(FalseClass) ),
    "type"     => plan.type
  )
end

def task_hash_including_for(task:)
  a_hash_including(
    "id" => task.id,
    "opens_at" => DateTimeUtilities.to_api_s(task.opens_at),
    "due_at"   => DateTimeUtilities.to_api_s(task.due_at),
    "type"     => task.task_type,
    "complete" => task.completed?
  )
end

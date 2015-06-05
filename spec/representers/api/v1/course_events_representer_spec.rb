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
  hash = {
    "id"       => plan.id.to_s,
    "trouble"  => be_a_kind_of(TrueClass).or( be_a_kind_of(FalseClass) ),
    "type"     => plan.type,
    "periods"  => plan.tasking_plans.collect do |tp|
      {
        "id" => tp.target_id,
        "opens_at" => DateTimeUtilities.to_api_s(tp.opens_at),
        "due_at" => DateTimeUtilities.to_api_s(tp.due_at)
      }
    end
  }
  hash["title"] = plan.title unless plan.title.nil?

  a_hash_including hash
end

def task_hash_including_for(task:)
  hash = {
    "id"       => task.id.to_s,
    "opens_at" => DateTimeUtilities.to_api_s(task.opens_at),
    "due_at"   => DateTimeUtilities.to_api_s(task.due_at),
    "type"     => task.task_type,
    "complete" => task.completed?
  }
  hash["title"] = task.title unless task.title.nil?

  a_hash_including hash
end

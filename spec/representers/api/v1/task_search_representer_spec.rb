require 'rails_helper'

RSpec.describe Api::V1::TaskSearchRepresenter, :type => :representer do

  it "represents a generates a JSON representation of their tasks" do
    task_count = rand(5..10)
    tasks = task_count.times.collect{ FactoryGirl.create(:tasks_task) }

    outputs = Hashie::Mash.new({
      items: tasks
    })

    representation = Api::V1::TaskSearchRepresenter.new(outputs).as_json

    expect(representation).to include(
      "total_count" => task_count,
      "items" => outputs[:items].map{ | item |
        json = item.as_json.slice('id', 'title', 'task_plan_id', 'is_shared', 'steps')
        json['opens_at']  = DateTimeUtilities.to_api_s(item.opens_at)
        json['due_at']    = DateTimeUtilities.to_api_s(item.due_at)
        json['is_shared'] = item.is_shared
        json['steps']     = item.task_steps.as_json
        json
      }
    )
  end

end

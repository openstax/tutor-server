require 'rails_helper'

RSpec.describe Api::V1::TaskedReadingRepresenter, :type => :representer do
  it "should represent a basic reading" do
    task_step = FactoryGirl.create(:tasks_tasked_reading).task_step
    json = Api::V1::TaskedReadingRepresenter.new(task_step.tasked).to_json

    expect(JSON.parse(json)).to eq({
      id: task_step.id,
      task_id: task_step.tasks_task_id,
      type: "reading",
      title: task_step.tasked.title,
      is_completed: false,
      content_url: task_step.tasked.url,
      content_html: task_step.tasked.content
    }.stringify_keys)
  end
end

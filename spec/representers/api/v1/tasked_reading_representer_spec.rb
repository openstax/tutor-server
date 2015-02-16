require 'rails_helper'

RSpec.describe Api::V1::TaskedReadingRepresenter, :type => :representer do
  it "should represent a basic reading" do
    task_step = FactoryGirl.create(:tasked_reading).task_step
    json = Api::V1::TaskedReadingRepresenter.new(task_step).to_json

    expect(json).to eq({
      id: task_step.id,
      type: "reading",
      title: task_step.title,
      is_completed: false,
      content_url: task_step.url, 
      content_html: task_step.content
    }.to_json)
  end
end

require 'rails_helper'

RSpec.describe Api::V1::TaskStep::ReadingRepresenter, :type => :representer do
  it "should represent a basic reading" do
    reading = FactoryGirl.create(:task_step_reading)
    json = Api::V1::TaskStep::ReadingRepresenter.new(reading.task_step).to_json
    expect(json).to eq({
      id: reading.task_step.id,
      type: reading.task_step.step_type.downcase,
      title: reading.task_step.title,
      content_url: reading.task_step.url, 
      content_html: reading.task_step.content
    }.to_json)
  end
end

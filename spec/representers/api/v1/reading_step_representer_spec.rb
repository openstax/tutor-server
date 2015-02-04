require 'rails_helper'

RSpec.describe Api::V1::ReadingStepRepresenter, :type => :representer do
  it "should represent a basic reading" do
    reading_step = FactoryGirl.create(:reading_step)
    json = Api::V1::ReadingStepRepresenter.new(reading_step.task_step).to_json
    expect(json).to eq({
      id: reading_step.task_step.id,
      type: reading_step.task_step.step_type.downcase,
      title: reading_step.task_step.title,
      content_url: reading_step.task_step.url, 
      content_html: reading_step.task_step.content
    }.to_json)
  end
end

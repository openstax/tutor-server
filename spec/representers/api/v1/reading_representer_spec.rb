require 'rails_helper'

RSpec.describe Api::V1::ReadingRepresenter, :type => :representer do
  it "should represent a basic reading" do
    reading = FactoryGirl.create(:reading)
    json = Api::V1::ReadingRepresenter.new(reading.task_step).to_json
    expect(json).to eq({
      id: reading.task_step.id,
      type: reading.task_step.details_type.downcase,
      title: reading.task_step.title,
      content_url: reading.url, 
      content_html: reading.content
    }.to_json)
  end
end

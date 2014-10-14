require 'rails_helper'

RSpec.describe Api::V1::ReadingRepresenter, :type => :representer do
  it "should represent a basic reading" do
    reading = FactoryGirl.create(:reading)
    json = Api::V1::ReadingRepresenter.new(reading).to_json
    expect(json).to eq({
      id: reading.task.id,
      type: "reading",
      task_plan_id: nil,
      opens_at: reading.opens_at,
      due_at: reading.due_at,
      is_shared: reading.is_shared,
      content_url: reading.url, 
      content_html: reading.content
    }.to_json)
  end
end

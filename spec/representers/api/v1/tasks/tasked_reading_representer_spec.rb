require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedReadingRepresenter, type: :representer do
  it "should represent a basic reading" do
    task_step = FactoryBot.create(:tasks_tasked_reading).task_step
    json = Api::V1::Tasks::TaskedReadingRepresenter.new(task_step.tasked).to_json

    expect(JSON.parse(json)).to include({
      id: task_step.id,
      type: "reading",
      group: 'unknown',
      title: task_step.tasked.title,
      chapter_section: task_step.tasked.book_location,
      is_completed: false,
      preview: task_step.tasked.content_preview,
      content_url: task_step.tasked.url
    }.stringify_keys)
  end

  it "has additional content fields" do
    task_step = FactoryBot.create(:tasks_tasked_reading).task_step
    json = Api::V1::Tasks::TaskedReadingRepresenter.new(task_step.tasked).to_json(
      user_options: { include_content: true }
    )
    expect(JSON.parse(json)).to include({
      html: task_step.tasked.content,
      has_learning_objectives: task_step.tasked.has_learning_objectives?,
    }.stringify_keys)
  end

end

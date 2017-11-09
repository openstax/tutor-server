require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedReadingRepresenter, type: :representer do
  it "should represent a basic reading" do
    task_step = FactoryBot.create(:tasks_tasked_reading).task_step
    json = Api::V1::Tasks::TaskedReadingRepresenter.new(task_step.tasked).to_json

    expect(JSON.parse(json)).to include({
      id: task_step.id.to_s,
      task_id: task_step.tasks_task_id.to_s,
      type: "reading",
      title: task_step.tasked.title,
      chapter_section: task_step.tasked.book_location,
      is_completed: false,
      has_recovery: false,
      content_url: task_step.tasked.url,
      content_html: task_step.tasked.content,
      related_content: a_kind_of(Array),
      spy: {}
    }.stringify_keys)
  end
end

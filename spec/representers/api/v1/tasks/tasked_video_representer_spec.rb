require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedVideoRepresenter, type: :representer do
  it 'should represent a video' do
    task_step = FactoryBot.create(:tasks_tasked_video).task_step
    json = Api::V1::Tasks::TaskedVideoRepresenter.new(task_step.tasked).to_json

    expect(JSON.parse(json)).to include({
      id: task_step.id.to_s,
      task_id: task_step.tasks_task_id.to_s,
      type: 'video',
      title: task_step.tasked.title,
      is_completed: false,
      has_recovery: false,
      content_url: task_step.tasked.url,
      content_html: task_step.tasked.content,
      related_content: a_kind_of(Array),
      spy: {}
    }.stringify_keys)
  end
end

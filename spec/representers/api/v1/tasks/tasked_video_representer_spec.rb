require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedVideoRepresenter, type: :representer do
  it 'should represent a video' do
    task_step = FactoryBot.create(:tasks_tasked_video).task_step
    json = Api::V1::Tasks::TaskedVideoRepresenter.new(task_step.tasked).to_json

    expect(JSON.parse(json)).to include({
      id: task_step.id,
      type: 'video',
      title: task_step.tasked.title,
      preview: task_step.tasked.content_preview,
      url: task_step.tasked.url,
    }.stringify_keys)
  end

end

require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedVideoRepresenter, type: :representer do
  it 'should represent a video' do
    task_step = FactoryBot.create(:tasks_tasked_video).task_step
    json = Api::V1::Tasks::TaskedVideoRepresenter.new(task_step.tasked).to_json

    expect(JSON.parse(json)).to include({
      id: task_step.id,
      type: 'video',
      group: task_step.group_name,
      is_core: task_step.is_core,
      title: task_step.tasked.title,
      preview: task_step.tasked.content_preview,
      url: task_step.tasked.url,
    }.stringify_keys)
  end

  it "has additional content fields" do
    task_step = FactoryBot.create(:tasks_tasked_reading).task_step
    json = Api::V1::Tasks::TaskedVideoRepresenter.new(task_step.tasked).to_json(
      user_options: { include_content: true }
    )
    expect(JSON.parse(json)).to include({
      html: task_step.tasked.content,
    }.stringify_keys)
  end

end

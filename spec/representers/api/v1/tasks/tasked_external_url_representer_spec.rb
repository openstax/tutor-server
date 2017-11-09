require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedExternalUrlRepresenter, type: :representer do
  it 'should represent a tasked external url' do
    task_step = FactoryBot.create(:tasks_tasked_external_url).task_step
    json = Api::V1::Tasks::TaskedExternalUrlRepresenter.new(task_step.tasked).to_json
    related_content = task_step.related_content.map do |rc|
      Api::V1::RelatedContentRepresenter.new(OpenStruct.new(rc)).to_hash
    end

    expect(JSON.parse(json)).to include({
      id: task_step.id.to_s,
      task_id: task_step.tasks_task_id.to_s,
      type: 'external_url',
      title: task_step.tasked.title,
      external_url: task_step.tasked.url,
      group: 'unknown',
      is_completed: false,
      has_recovery: false,
      labels: task_step.labels,
      related_content: related_content,
      spy: task_step.spy
    }.stringify_keys)
  end
end

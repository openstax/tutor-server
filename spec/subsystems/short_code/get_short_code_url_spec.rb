require 'rails_helper'

RSpec.describe ShortCode::GetShortCodeUrl, type: :routine do
  let(:absolute_url) { FactoryBot.create :short_code_short_code,
                                          uri: 'http://www.openstaxcollege.org/' }

  let(:relative_url) { FactoryBot.create :short_code_short_code, uri: '/courses/1/' }

  let(:task_plan) { FactoryBot.create :tasks_task_plan }
  let(:task_plan_gid) { task_plan.to_global_id.to_s }

  let(:task_plan_url) { FactoryBot.create :short_code_short_code, uri: task_plan_gid }

  let(:tasking) { FactoryBot.create :tasks_tasking }
  let(:tasking_gid) { tasking.to_global_id.to_s }
  let(:tasking_url) { FactoryBot.create :short_code_short_code, uri: tasking_gid }

  let(:user) { FactoryBot.create :user_profile }

  it 'returns absolute urls' do
    result = described_class.call(short_code: absolute_url.code, user: user)
    expect(result.outputs.uri).to eq(absolute_url.uri)
  end

  it 'returns relative urls' do
    result = described_class.call(short_code: relative_url.code, user: user)
    expect(result.outputs.uri).to eq(relative_url.uri)
  end

  it 'returns task plan url returned by Tasks::GetRedirectUrl' do
    outputs = Lev::Outputs.new(uri: 'task-plan-url')
    result = Lev::Routine::Result.new(outputs, Lev::Errors.new)
    expect_any_instance_of(Tasks::GetRedirectUrl).to receive(:call).and_return(result)
    result = described_class.call(short_code: task_plan_url.code, user: user)
    expect(result.outputs.uri).to eq('task-plan-url')
  end

  it 'returns an error if the uri is a GID but is not a task plan' do
    result = described_class.call(short_code: tasking_url.code, user: user)
    expect(result.errors.first.code).to eq(:no_handler_for_gid)
  end

  it 'returns an error if the short code is not found' do
    result = described_class.call(short_code: 'notfound', user: user)
    expect(result.errors.first.code).to eq(:short_code_not_found)
  end
end

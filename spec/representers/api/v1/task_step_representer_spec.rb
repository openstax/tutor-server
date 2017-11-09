require 'rails_helper'

RSpec.describe Api::V1::TaskStepRepresenter, type: :representer do
  it 'includes the *complete_at fields' do
    last_time = Time.current
    first_time = last_time - 1.week
    formatted_first_time = DateTimeUtilities.to_api_s(first_time)
    formatted_last_time = DateTimeUtilities.to_api_s(last_time)
    task_step = FactoryBot.create(:tasks_task_step, first_completed_at: first_time,
                                                     last_completed_at: last_time)

    representation = described_class.prepare(task_step).to_hash

    expect(representation).to include('first_completed_at' => formatted_first_time,
                                      'last_completed_at' => formatted_last_time)
  end
end

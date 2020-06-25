require 'rails_helper'

RSpec.describe Api::V1::TaskStepRepresenter, type: :representer do
  it 'includes the is_completed field' do
    last_time = Time.current
    first_time = last_time - 1.week
    task_step = FactoryBot.create(:tasks_task_step, first_completed_at: first_time,
                                                    last_completed_at: last_time)

    representation = described_class.prepare(task_step).to_hash

    expect(representation).to include('is_completed' => true)
  end

  it 'includes the can_be_updated and last_updated_at fields' do
    last_time = Time.current
    first_time = last_time - 1.week
    task_step = FactoryBot.create(:tasks_task_step, first_completed_at: first_time,
                                                    last_completed_at: last_time)

    representation = described_class.prepare(task_step).to_hash

    expect(representation).to include('can_be_updated' => false)
    expect(representation).to include('last_completed_at' => DateTimeUtilities.to_api_s(last_time))
  end
end

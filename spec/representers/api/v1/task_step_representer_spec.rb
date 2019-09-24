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
end

require 'rails_helper'

RSpec.describe Api::V1::TaskStepRepresenter do
  it 'includes the *complete_at fields' do
    time = Time.current
    task_step = FactoryGirl.create(:tasks_task_step, first_completed_at: time - 1.week,
                                                     last_completed_at: time)

    representation = described_class.prepare(task_step).to_hash
    expect(representation).to include('first_completed_at' => time - 1.week,
                                      'last_completed_at' => time)
  end
end

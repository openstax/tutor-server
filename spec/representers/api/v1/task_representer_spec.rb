require 'rails_helper'

RSpec.describe Api::V1::TaskRepresenter, type: :representer do
  it 'includes the last_worked_at property' do
    time = Time.current
    task = FactoryGirl.create(:tasks_task)
    formatted_time = DateTimeUtilities.to_api_s(time)

    task.set_last_worked_at(time: time)
    task.save

    represented = described_class.new(task).to_hash

    expect(represented).to include('last_worked_at' => formatted_time)
  end
end

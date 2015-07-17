require 'rails_helper'

RSpec.describe Api::V1::TaskRepresenter, type: :representer do
  it 'includes the last_worked_at property' do
    time = Time.current
    task = FactoryGirl.create(:tasks_task)
    formatted_time = DateTimeUtilities.to_api_s(time)

    task.last_worked!(time: time)

    represented = described_class.new(task).to_hash

    expect(represented).to include('last_worked_at' => formatted_time)
  end
end

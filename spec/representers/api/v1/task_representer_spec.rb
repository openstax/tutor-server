require 'rails_helper'

RSpec.describe Api::V1::TaskRepresenter, type: :representer do

  let(:task) {FactoryGirl.create(:tasks_task)}

  it 'includes the last_worked_at property' do
    time = Time.current
    formatted_time = DateTimeUtilities.to_api_s(time)

    task.set_last_worked_at(time: time)
    task.save

    represented = described_class.new(task).to_hash

    expect(represented).to include('last_worked_at' => formatted_time)
  end

  it 'includes ecosystem information' do
    represented = described_class.new(task).to_hash
    expect(represented).to include('ecosystem_title' => task.ecosystem.title)
  end

end

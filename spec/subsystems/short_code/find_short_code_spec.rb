require 'rails_helper'

RSpec.describe ShortCode::FindShortCode, type: :routine do
  let(:task_plan) { FactoryBot.create :tasks_task_plan }

  it 'can find the short code for a model by using the id' do
    created_code = ShortCode::Create[task_plan.to_global_id.to_s]

    short_code = described_class[task_plan.to_global_id.to_s]
    expect(short_code).to eq(created_code)
  end
end

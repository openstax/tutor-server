require 'rails_helper'

RSpec.describe ShortCode::FindTaskPlanShortCode, type: :routine do
  let(:task_plan) { FactoryGirl.create :tasks_task_plan }


  it 'can generate the short code for a task plan by using the id' do
    created_code = ShortCode::Create[task_plan.to_global_id.to_s]

    short_code = described_class[task_plan.id]
    expect(short_code).to eq(created_code)
  end
end

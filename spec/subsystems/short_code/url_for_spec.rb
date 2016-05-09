require 'rails_helper'

RSpec.describe ShortCode::UrlFor, type: :routine do
  let(:task_plan) { FactoryGirl.create :tasks_task_plan }

  it 'can generate a url for a model' do
    code = ShortCode::Create[task_plan.to_global_id.to_s]
    url = described_class[task_plan]
    expect(url).to eq("/@#{code}/#{task_plan.title.parameterize}")
  end
end

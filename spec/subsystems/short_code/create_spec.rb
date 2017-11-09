require 'rails_helper'

RSpec.describe ShortCode::Create, type: :routine do
  it 'creates a short code using an absolute url' do
    short_code = described_class['http://www.openstaxcollege.org']
    expect(short_code).to be_present
    expect(ShortCode::Models::ShortCode.find_by_code(short_code).uri).to eq('http://www.openstaxcollege.org')
  end

  it 'creates a short code using a relative url' do
    short_code = described_class['/dashboard']
    expect(short_code).to be_present
    expect(ShortCode::Models::ShortCode.find_by_code(short_code).uri).to eq('/dashboard')
  end

  it 'creates a short code using a object GID' do
    task_plan = FactoryBot.create :tasks_task_plan
    short_code = described_class[task_plan.to_global_id.to_s]
    expect(ShortCode::Models::ShortCode.find_by_code(short_code).uri).to eq(task_plan.to_global_id.to_s)
  end
end

require 'rails_helper'

RSpec.describe AddSpyInfo, type: :routine do

  let(:ecosystem) { FactoryGirl.build(:content_ecosystem) }

  it 'sets spy info from an ecosystem' do
    dest = AddSpyInfo[to: {}, from:ecosystem]
    expect(dest.spy).to eq({'ecosystem_id' => ecosystem.id,
                            'ecosystem_title' => ecosystem.title})
  end

  it 'sets spy info from any model' do
    course = FactoryGirl.create(:entity_course)
    dest = AddSpyInfo[to: {}, from: course]
    expect(dest.spy).to eq({'course_id' => course.id})
  end

  it 'sets spy info from an array of models' do
    task = FactoryGirl.create(:entity_task)
    dest = AddSpyInfo[to: {}, from: [task, ecosystem]]
    expect(dest.spy).to eq({'task_id' => task.id,
                            'ecosystem_id' => ecosystem.id,
                            'ecosystem_title' => ecosystem.title})
  end

end

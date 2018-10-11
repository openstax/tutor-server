require 'rails_helper'

RSpec.describe Research::Models::StudyBrain, type: :model do
  let(:cohort) { FactoryBot.create :research_cohort }
  let(:brain) {
    FactoryBot.create(
      :research_modified_task_for_display,
      study: cohort.study, code: "task.name='updated!'; return task"
    )
  }

  it 'has proper type' do
    expect(brain).to be_an(Research::Models::StudyBrain)
  end

  it 'evals code' do
    task = OpenStruct.new(name: '1234')
    expect(brain.modified_task_for_display(cohort: cohort, task: task)).to eq(task)
    expect(task.name).to eq 'updated!'
  end

  it 'raises exception for invalid code' do
    brain.update_attributes! code: 'bang()'
    bad_brain = Research::Models::StudyBrain.find(brain.id)
    task = OpenStruct.new(name: '1234')
    expect{
      bad_brain.modified_task_for_display(cohort: cohort, task: task)
    }.to raise_error(NoMethodError)
  end

  it 'finds for active study' do
    study = brain.study
    expect(described_class.active).to be_empty
    study.activate!
    expect(described_class.active).to eq [brain]
  end

end

require 'rails_helper'

RSpec.describe Research::Models::StudyBrain, type: :model do

  let(:brain) {
    # We need to find the newly created brain so that the
    # StudentTask's after_find block will execute and add it's "apply" method
    Research::Models::StudyBrain.find(
      FactoryBot.create(
        :research_display_student_task,
        code: "task.name='updated!'; return task"
      ).id
    )
  }

  it 'has proper type' do
    expect(brain).to be_an(Research::Models::StudyBrain)
  end

  it 'evals code' do
    task = OpenStruct.new(name: '1234')
    expect(brain.task_for_display(task: task)).to eq(task)
    expect(task.name).to eq 'updated!'
  end

  it 'raises exception for invalid code' do
    brain.update_attributes! code: 'bang()'
    bad_brain = Research::Models::StudyBrain.find(brain.id)
    task = OpenStruct.new(name: '1234')
    expect{
      bad_brain.task_for_display(task: task)
    }.to raise_error(NoMethodError)
  end

  it 'finds for active study' do
    study = brain.cohort.study
    expect(described_class.active).to be_empty
    study.activate!
    expect(described_class.active).to eq [brain]
  end

end

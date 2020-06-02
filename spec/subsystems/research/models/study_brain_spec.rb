require 'rails_helper'

RSpec.describe Research::Models::StudyBrain, type: :model do
  let(:cohort) { FactoryBot.create :research_cohort }
  let(:task_step) { FactoryBot.build(:tasks_task_step) }
  let(:task) { task_step.task }
  let(:code) { "task.title='updated!'; manipulation.record!; return task" }
  let(:brain) do
    FactoryBot.create(
      :research_modified_task,
      study: cohort.study, code: code
    )
  end

  it 'has proper type' do
    expect(brain).to be_an(Research::Models::StudyBrain)
  end

  it 'evals and returns result' do
    expect(brain.modified_task(cohort: cohort, task: task)).to eq(task)
    expect(task.title).to eq 'updated!'
  end

  it 'raises exception for invalid code' do
    brain.update_attributes! code: 'bang()'
    expect(Raven).to receive(:capture_message).with /study brain code: bang()/
    bad_brain = Research::Models::StudyBrain.find(brain.id)
    expect {
      expect{
        bad_brain.modified_task(cohort: cohort, task: task)
      }.to raise_error(NoMethodError)
    }.not_to change { brain.manipulations.count }
  end

  it 'finds for active study' do
    study = brain.study
    expect(described_class.active).to be_empty
    study.activate!
    expect(described_class.active).to eq [brain]
  end

  context 'recording the manipulation' do
    let(:code) { "manipulation.record!\nreturn 1234" }
    let(:brain) do
      FactoryBot.create(
        :research_modified_tasked,
        study: cohort.study, code: code
      )
    end
    let(:task_step) { FactoryBot.build(:tasks_tasked_exercise).task_step }

    it 'can be recorded from a brain and returns original value' do
      expect do
        result = brain.modified_tasked(cohort: cohort, tasked: task_step.tasked)
        expect(result).to eq 1234
      end.to change { brain.manipulations.count }.by 1
    end
    context 'without a call to record' do
      let(:code){ 'manipulation.ignore!; tasked' } # no call to record
      it 'a brain can choose not to record manipulation' do
        expect do
          brain.modified_tasked(cohort: cohort, tasked: task_step.tasked)
        end.to change { brain.manipulations.count }.by 0
      end
    end

  end
end

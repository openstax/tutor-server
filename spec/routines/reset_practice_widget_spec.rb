require 'rails_helper'

RSpec.describe ResetPracticeWidget, type: :routine do

  let!(:role)          { Entity::Role.create! }
  let!(:practice_task) { ResetPracticeWidget[role: role, exercise_source: :fake, page_ids: []] }

  it 'creates tasks with 5 exercise steps and feedback immediately available' do
    expect(practice_task).to be_persisted
    expect(practice_task.task.task_steps.reload.size).to eq 5
    practice_task.task.task_steps.each{ |task_step| expect(task_step.exercise?).to eq true }
    expect(practice_task.task.feedback_available?).to be_truthy
  end

  it 'clears incomplete steps from previous practice widgets' do
    MarkTaskStepCompleted[task_step: practice_task.task.task_steps.first]
    practice_task_2 = ResetPracticeWidget[role: role, exercise_source: :fake, page_ids: []]
    expect(practice_task_2).to be_persisted
    expect(practice_task.task.task_steps.reload.size).to eq 1
  end

  it 'errors when biglearn does not return enough' do
    allow(OpenStax::Biglearn::V1).to receive(:get_projection_exercises) { ['dummy_url'] }
    result = ResetPracticeWidget.call(role: role, exercise_source: :biglearn, page_ids: [])
    expect(result.errors.first.code).to eq :missing_local_exercises
  end

  it 'errors when there are not enough exercises returned for the widget' do
    allow_any_instance_of(ResetPracticeWidget).to receive(:get_fake_exercises) { [] }
    result = ResetPracticeWidget.call(role: role, exercise_source: :fake, page_ids: [])
    expect(result.errors.first.code).to eq :not_enough_exercises
  end

end

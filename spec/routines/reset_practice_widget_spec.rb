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

end

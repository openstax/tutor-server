require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetTaskPlans, type: :routine do
  let!(:task_plan_1) { FactoryGirl.create :tasked_task_plan }
  let(:course)       { task_plan_1.owner }
  let!(:task_plan_2) { FactoryGirl.create :tasks_task_plan, owner: course }
  let!(:task_plan_3) { FactoryGirl.create :tasks_task_plan, owner: course }

  it 'gets all task_plans in a course' do
    out = described_class.call(owner: course).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_nil
  end

  it 'can return the task_plan ids for which there is trouble' do
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    # 10 tasks in total
    tasks = task_plan_1.tasks.preload(task_steps: :tasked).to_a

    # Remove placeholder steps since they can sometimes be deleted, messing up our counting
    tasks.each do |task|
      task.task_steps.select(&:placeholder?).each(&:really_destroy!)
      task.reload.update_step_counts!
    end

    tasks.first(2).each do |task|
      task.task_steps.each do |task_step|
        if task_step.exercise?
          Demo::AnswerExercise[task_step: task_step, is_correct: false]
        else
          MarkTaskStepCompleted[task_step: task_step]
        end
      end
    end

    # Not enough tasks completed: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    tasks[2].task_steps.each do |task_step|
      if task_step.exercise?
        Demo::AnswerExercise[task_step: task_step, is_correct: false]
      else
        MarkTaskStepCompleted[task_step: task_step]
      end
    end

    # >25% completed: trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to include(task_plan_1.id)

    tasks[3..5].each do |task|
      task.task_steps.each do |task_step|
        if task_step.exercise?
          Demo::AnswerExercise[task_step: task_step, is_correct: true]
        else
          MarkTaskStepCompleted[task_step: task_step]
        end
      end
    end

    # 50% correct: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    tasks[6].task_steps.each do |task_step|
      if task_step.exercise?
        Demo::AnswerExercise[task_step: task_step, is_correct: false]
      else
        MarkTaskStepCompleted[task_step: task_step]
      end
    end

    # Less than 50% correct: trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to include(task_plan_1.id)

    tasks[7].task_steps.each do |task_step|
      if task_step.exercise?
        Demo::AnswerExercise[task_step: task_step, is_correct: true]
      else
        MarkTaskStepCompleted[task_step: task_step]
      end
    end

    # 50% correct: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    tasks[8].task_steps.each do |task_step|
      if task_step.exercise?
        Demo::AnswerExercise[task_step: task_step, is_correct: false]
      else
        MarkTaskStepCompleted[task_step: task_step]
      end
    end

    # Less than 50% correct: trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to include(task_plan_1.id)

    tasks[9].task_steps.each do |task_step|
      if task_step.exercise?
        Demo::AnswerExercise[task_step: task_step, is_correct: true]
      else
        MarkTaskStepCompleted[task_step: task_step]
      end
    end

    # 50% correct: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty
  end
end

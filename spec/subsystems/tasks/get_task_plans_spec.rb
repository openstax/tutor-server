require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetTaskPlans, type: :routine, speed: :medium do
  let!(:task_plan_1) { FactoryBot.create :tasked_task_plan }
  let(:course)       { task_plan_1.owner }
  let!(:task_plan_2) { FactoryBot.create :tasks_task_plan, owner: course }
  let!(:task_plan_3) { FactoryBot.create :tasks_task_plan, owner: course }

  it 'gets all task_plans in a course' do
    out = described_class.call(owner: course).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_nil
  end

  # TODO: Move to GetTpDashboard spec
  xit 'can return the task_plan ids for which there is trouble' do
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    # 10 tasks in total
    student_tasks = task_plan_1.tasks.joins(taskings: {role: :student})
                                     .preload(task_steps: :tasked)
                                     .to_a

    # Remove placeholder steps since they can sometimes be deleted, messing up our counting
    student_tasks.each do |task|
      task.task_steps.select(&:placeholder?).each(&:destroy!)
      task.pes_are_assigned = true
      task.spes_are_assigned = true
      task.touch
    end

    student_tasks.first(2).each { |task| Preview::WorkTask[task: task, is_correct: false] }

    # Not enough tasks completed: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    Preview::WorkTask[task: student_tasks[2], is_correct: false]

    # >25% completed: trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to include(task_plan_1.id)

    student_tasks[3..5].each { |task| Preview::WorkTask[task: task, is_correct: true] }

    # 50% correct: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    Preview::WorkTask[task: student_tasks[6], is_correct: false]

    # Less than 50% correct: trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to include(task_plan_1.id)

    Preview::WorkTask[task: student_tasks[7], is_correct: true]

    # 50% correct: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty

    Preview::WorkTask[task: student_tasks[8], is_correct: false]

    # Less than 50% correct: trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to include(task_plan_1.id)

    Preview::WorkTask[task: student_tasks[9], is_correct: true]

    # 50% correct: no trouble
    out = described_class.call(owner: course, include_trouble_flags: true).outputs
    expect(out[:plans].length).to eq 3
    expect(out[:plans]).to include(task_plan_1, task_plan_2, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_empty
  end

  it 'does not return withdrawn task_plans' do
    task_plan_2.destroy
    out = described_class.call(owner: course).outputs
    expect(out[:plans].length).to eq 2
    expect(out[:plans]).to include(task_plan_1, task_plan_3)
    expect(out[:trouble_plan_ids]).to be_nil
  end
end

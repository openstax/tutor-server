require 'rails_helper'

RSpec.describe TaskExercise, type: :routine do
  let(:exercise) { FactoryBot.create(:content_exercise) }

  let(:multipart_exercise) do
    FactoryBot.create(:content_exercise, num_questions: 2, context: 'Some context')
  end

  let(:task) { FactoryBot.create :tasks_task }

  it 'builds a TaskedExercise for the given exercise and task_step (and saves when task saved)' do
    expect do
      described_class[exercise: exercise, task: task, group_type: :fixed_group, is_core: true]
    end.to change { task.task_steps.count }.from(0).to(1)

    task_step = task.task_steps.last

    expect(task_step.page).to eq exercise.page
    expect(task_step.fixed_group?).to eq true
    expect(task_step.is_core).to eq true
    expect(task_step.labels).to eq []
    expect(task_step.spy).to eq({})
    expect(task_step.tasked).to be_a(Tasks::Models::TaskedExercise)
    expect(task_step.tasked).to be_persisted
    expect(task_step.tasked.is_in_multipart).to eq false
    expect(task_step.tasked.question_index).to eq 0
    expect(task_step.tasked.question_id).to be_kind_of(String)
    expect(task_step.tasked.task_step).to eq task_step
    parser = task_step.tasked.parser
    expect(parser.url).to eq exercise.url
    expect(parser.title).to eq exercise.title
    expect(parser.content).to eq exercise.content
  end

  it 'builds two TaskedExercises for a multipart' do
    expect do
      TaskExercise[
        exercise: multipart_exercise, task: task, group_type: :personalized_group, is_core: true
      ]
    end.to change { task.task_steps.count }.from(0).to(2)

    question_ids = multipart_exercise.questions.map(&:id)

    expect(task.task_steps.size).to eq 2

    task.task_steps.each_with_index do |task_step, index|
      expect(task_step.tasked).to be_a Tasks::Models::TaskedExercise
      expect(task_step.tasked.is_in_multipart).to eq true
      expect(task_step.tasked.context).to eq 'Some context'
      expect(task_step.page).to eq multipart_exercise.page
      expect(task_step.personalized_group?).to eq true
      expect(task_step.is_core).to eq true
      expect(task_step.labels).to eq []
      expect(task_step.spy).to eq({})
      expect(task_step.tasked.question_index).to eq index
      expect(task_step.tasked.question_id).to eq question_ids[index]
      expect(task_step.tasked.content).to match("(#{index})")
    end
  end

  it 'can build just some parts of a multipart' do
    task_step = FactoryBot.create(:tasks_tasked_placeholder).task_step
    task = task_step.task

    expect do
      TaskExercise[exercise: multipart_exercise, task_steps: [ task_step ]]
    end.to  not_change { task.task_steps.count }
       .and not_change { task_step.reload.group_type }
       .and not_change { task_step.is_core }
       .and not_change { task_step.labels }
       .and not_change { task_step.spy }

    question_id = multipart_exercise.questions.first.id

    expect(task.task_steps.reload.size).to eq 1

    task_step = task.task_steps.first

    expect(task_step.tasked).to be_a Tasks::Models::TaskedExercise
    expect(task_step.tasked.is_in_multipart).to eq true
    expect(task_step.tasked.context).to eq 'Some context'
    expect(task_step.page).to eq multipart_exercise.page
    expect(task_step.tasked.question_index).to eq 0
    expect(task_step.tasked.question_id).to eq question_id
    expect(task_step.tasked.content).to match("(0)")
  end
end

require 'rails_helper'

RSpec.describe TaskExercise, type: :routine do

  let(:exercise)  do
    content_exercise = FactoryBot.create(:content_exercise)
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end

  let(:multipart_exercise)  do
    content_exercise = FactoryBot.create(
      :content_exercise, num_questions: 2, context: 'Some context'
    )
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end

  let(:task_step) { FactoryBot.build(:tasks_task_step) }

  it 'builds a TaskedExercise for the given exercise and task_step (and saves when task saved)' do
    task_step.save!

    TaskExercise[exercise: exercise, task_step: task_step]

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
    task = task_step.task

    TaskExercise[exercise: multipart_exercise, task_step: task_step, task: task]

    question_ids = multipart_exercise.to_model.questions.map(&:id)

    expect(task.task_steps.length).to eq 2

    task.task_steps.each do |ts|
      expect(ts.tasked).to be_a Tasks::Models::TaskedExercise
      expect(ts.tasked.is_in_multipart).to eq true
      expect(ts.tasked.context).to eq 'Some context'
      expect(ts.group_type).to eq task_step.group_type
      expect(ts.page).to eq multipart_exercise.page.to_model
      expect(ts.labels).to eq []
    end
    expect(task.task_steps[0].tasked.question_index).to eq 0
    expect(task.task_steps[0].tasked.question_id).to eq question_ids[0]
    expect(task.task_steps[0].tasked.content).to match("(0)")
    expect(task.task_steps[1].tasked.question_index).to eq 1
    expect(task.task_steps[1].tasked.question_id).to eq question_ids[1]
    expect(task.task_steps[1].tasked.content).to match("(1)")
  end

  it 'can insert multiple exercise steps in order for a single placeholder step' do
    task = FactoryBot.create :tasks_task, step_types: [
      :tasks_tasked_reading, :tasks_tasked_placeholder, :tasks_tasked_exercise
    ]
    reading_step = task.task_steps.first
    placeholder_step = task.task_steps.second
    exercise_step = task.task_steps.third

    placeholder_step.update_attributes group_type: :personalized_group, labels: ['test']

    TaskExercise[exercise: multipart_exercise, task_step: placeholder_step, task: task]

    question_ids = multipart_exercise.to_model.questions.map(&:id)

    expect(task.task_steps.length).to eq 4
    expect(task.task_steps[0]).to eq reading_step

    expect(task.task_steps[1]).to eq placeholder_step
    task.task_steps[1..2].each do |task_step|
      expect(task_step.tasked).to be_a Tasks::Models::TaskedExercise
      expect(task_step.tasked.is_in_multipart).to eq true
      expect(task_step.tasked.context).to eq 'Some context'
      expect(task_step.group_type).to eq 'personalized_group'
      expect(task_step.page).to eq multipart_exercise.page.to_model
      expect(task_step.labels).to eq ['test']
    end
    expect(task.task_steps[1].tasked.question_index).to eq 0
    expect(task.task_steps[1].tasked.question_id).to eq question_ids[0]
    expect(task.task_steps[1].tasked.content).to match("(0)")
    expect(task.task_steps[2].tasked.question_index).to eq 1
    expect(task.task_steps[2].tasked.question_id).to eq question_ids[1]
    expect(task.task_steps[2].tasked.content).to match("(1)")

    expect(task.task_steps[3]).to eq exercise_step
    expect(task.task_steps[3].tasked.is_in_multipart).to eq false
    expect(task.task_steps[3].page).not_to eq multipart_exercise.page.to_model
  end

end

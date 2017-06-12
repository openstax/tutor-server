require 'rails_helper'

RSpec.describe TaskExercise, type: :routine do
  let(:exercise)  do
    content_exercise = FactoryGirl.create(:content_exercise)
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end

  let(:multipart_exercise)  do
    content_exercise = FactoryGirl.create(:content_exercise, num_parts: 2, context: 'Some context')
    strategy = Content::Strategies::Direct::Exercise.new(content_exercise)
    Content::Exercise.new(strategy: strategy)
  end

  let(:task_step) { FactoryGirl.build(:tasks_task_step) }

  it 'builds a TaskedExercise for the given exercise and task_step (and saves when task saved)' do
    TaskExercise[exercise: exercise, task_step: task_step]
    expect(task_step.tasked).to be_a(Tasks::Models::TaskedExercise)
    expect(task_step.tasked).to be_persisted
    expect(task_step.tasked.is_in_multipart).to be_falsy
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

    expect(task.task_steps.length).to eq 2
    expect(task.task_steps.first).to eq task_step

    expected_content = ["(0)", "(1)"]

    task.tasked_exercises.each_with_index do |tasked_exercise, index|
      expect(tasked_exercise.is_in_multipart).to eq true
      expect(tasked_exercise.context).to eq 'Some context'
      expect(tasked_exercise.content).to include expected_content[index]
    end
  end

  it 'can insert multiple exercise steps in order for a single placeholder step' do
    task = FactoryGirl.create :tasks_task,
                              step_types: [:tasks_tasked_reading,
                                           :tasks_tasked_placeholder,
                                           :tasks_tasked_exercise]
    reading_step = task.task_steps.first
    placeholder_step = task.task_steps.second
    exercise_step = task.task_steps.third

    placeholder_step.update_attributes(
      group_type: :personalized_group, labels: ['test']
    )

    TaskExercise[exercise: multipart_exercise, task_step: placeholder_step, task: task]

    question_ids = multipart_exercise.content_as_independent_questions.map{ |qq| qq[:id] }

    expect(task.task_steps.length).to eq 4
    expect(task.task_steps[0]).to eq reading_step

    expect(task.task_steps[1]).to eq placeholder_step
    task.task_steps[1..2].each do |task_step|
      expect(task_step.tasked).to be_a Tasks::Models::TaskedExercise
      expect(task_step.tasked.is_in_multipart).to be_truthy
      expect(task_step.group_type).to eq 'personalized_group'
      expect(task_step.related_content).to eq [{'test' => true}]
      expect(task_step.labels).to eq ['test']
    end
    expect(task.task_steps[1].tasked.question_id).to eq question_ids[0]
    expect(task.task_steps[2].tasked.question_id).to eq question_ids[1]
    expect(task.task_steps[1].tasked.content).to match("(0)")
    expect(task.task_steps[2].tasked.content).to match("(1)")

    expect(task.task_steps[3]).to eq exercise_step
    expect(task.task_steps[3].tasked.is_in_multipart).to be_falsy
  end

end

require 'rails_helper'
require 'vcr_helper'

RSpec.describe SearchLocalExercises, :type => :routine, :vcr => VCR_OPTS do

  let!(:book_part)     { FactoryGirl.create :content_book_part }

  let!(:cnx_page_hash) { { 'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083@11',
                           'title' => 'Force' } }

  let!(:cnx_page)      { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

  let!(:role)          { Entity::Role.create }

  let!(:exercise_1)    { FactoryGirl.create :content_exercise }
  let!(:exercise_2)    { FactoryGirl.create :content_exercise }
  let!(:exercise_3)    { FactoryGirl.create :content_exercise }

  let!(:test_tag)      { FactoryGirl.create :content_tag, value: 'test-tag' }

  it 'can search imported exercises' do
    OpenStax::Exercises::V1.configure do |config|
      config.server_url = 'http://exercises-dev1.openstax.org'
    end

    OpenStax::Exercises::V1.use_real_client

    Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                       book_part: book_part)

    url = Content::Models::Exercise.last.url
    exercises = SearchLocalExercises.call(url: url).outputs.items
    expect(exercises.length).to eq 1
    expect(exercises.first.url).to eq url

    lo = 'k12phys-ch04-s01-lo01'
    exercises = SearchLocalExercises.call(tag: lo).outputs.items
    expect(exercises.length).to eq 16
    exercises.each do |exercise|
      tags = exercise.tags
      expect(exercise.tags).to include(lo)
      expect(exercise.los).to include(lo)
    end

    embed_tag = 'k12phys-ch04-ex021'
    exercises = SearchLocalExercises.call(tag: embed_tag).outputs.items
    expect(exercises.length).to eq 1
    expect(exercises.first.tags).to include(embed_tag)
  end

  it 'can search exercises that have or have not been assigned to a role' do
    task_step = FactoryGirl.create :tasks_task_step
    task = task_step.task.reload

    task.entity_task.taskings << FactoryGirl.create(
      :tasks_tasking, task: task.entity_task, role: role
    )

    exercise_step_1 = Tasks::Models::TaskStep.new(task: task)
    exercise_step_2 = Tasks::Models::TaskStep.new(task: task)

    Content::Routines::TagResource.call(exercise_3, 'test-tag')

    TaskExercise[exercise: Exercise.new(exercise_1), task_step: exercise_step_1]
    TaskExercise[exercise: Exercise.new(exercise_2), task_step: exercise_step_2]

    task.task_steps << exercise_step_1
    task.task_steps << exercise_step_2
    task.save!

    out = SearchLocalExercises.call(assigned_to: role).outputs.items
    expect(out).to include(Exercise.new(exercise_1))
    expect(out).to include(Exercise.new(exercise_2))
    expect(out.length).to eq 2

    out = SearchLocalExercises.call(not_assigned_to: role,
                                            tag: 'test-tag').outputs.items
    expect(out).to eq [Exercise.new(exercise_3)]
  end

end

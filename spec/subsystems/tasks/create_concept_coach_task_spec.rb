require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::CreateConceptCoachTask, type: :routine do
  let!(:page_model)       { FactoryGirl.create :content_page }
  let!(:page)             { Content::Page.new(strategy: page_model.wrap) }

  let!(:exercise_model_1) { FactoryGirl.create :content_exercise, page: page_model }
  let!(:exercise_model_2) { FactoryGirl.create :content_exercise, page: page_model }
  let!(:exercise_model_3) { FactoryGirl.create :content_exercise, page: page_model }
  let!(:exercise_model_4) { FactoryGirl.create :content_exercise, page: page_model }
  let!(:exercise_model_5) { FactoryGirl.create :content_exercise, page: page_model }

  let!(:exercises)        do
    [exercise_model_5, exercise_model_4, exercise_model_3,
     exercise_model_2, exercise_model_1].map do |exercise_model|
      Content::Exercise.new(strategy: exercise_model.wrap)
    end
  end

  it 'creates a task containing the given exercises in the proper order' do
    task = nil
    expect{ task = described_class[page: page, exercises: exercises] }.to(
      change{ Tasks::Models::Task.count }.by(1)
    )
    expect(task.tasked_exercises.map(&:content_exercise_id)).to eq exercises.map(&:id)
  end

  it 'creates a ConceptCoachTask object' do
    task = nil
    expect{ task = described_class[page: page, exercises: exercises] }.to(
      change{ Tasks::Models::ConceptCoachTask.count }.by(1)
    )
    cc_task = Tasks::Models::ConceptCoachTask.order(:created_at).last
    expect(cc_task.task).to eq task.entity_task
    expect(cc_task.page).to eq page_model
  end
end

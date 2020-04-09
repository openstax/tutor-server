require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe FindOrCreatePracticeWorstTopicsTask, type: :routine do
  before do
    # Need some preexisting work to determine the worst areas
    book = FactoryBot.create :content_book, :standard_contents_1, ecosystem: ecosystem
    worked_pages = (
      2 * FindOrCreatePracticeTaskRoutine::NUM_EXERCISES
    ).times.map { FactoryBot.create :content_page, book: book }
    @worst_pages = worked_pages.sample FindOrCreatePracticeTaskRoutine::NUM_EXERCISES

    worked_pages.each do |page|
      is_correct = !@worst_pages.include?(page)
      task = FactoryBot.create :tasks_task, ecosystem: ecosystem, tasked_to: role
      OpenStax::Biglearn::Api::FakeClient::CLUE_MIN_NUM_RESPONSES.times do
        exercise = FactoryBot.create :content_exercise, page: page
        task_step = FactoryBot.create :tasks_task_step, task: task, page: page
        FactoryBot.create :tasks_tasked_exercise, exercise: exercise, task_step: task_step
        Preview::AnswerExercise.call task_step: task_step, is_correct: is_correct
      end

      # Make sure the worked pages have at least 1 unused practice widget exercise
      page.practice_widget_exercise_ids << FactoryBot.create(:content_exercise, page: page).id
      page.save!
    end
  end

  include_examples 'a routine that creates practice tasks',
                   -> { described_class.call course: course, role: role }

  it 'returns the expected pages' do
    expect(Set.new(result.outputs.task.task_steps.map(&:content_page_id))).to(
      eq Set.new(@worst_pages.map(&:id))
    )
  end

  it 'errors when there are not enough local exercises for the widget' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_practice_worst_areas_exercises).and_return(
      {
        accepted: true,
        exercises: [],
        spy_info: {}
      }
    )
    expect { result }
      .to  not_change { Tasks::Models::Task.count }
      .and not_change { Tasks::Models::Tasking.count }
      .and not_change { Tasks::Models::TaskStep.count }
      .and not_change { Tasks::Models::TaskedExercise.count }
      .and not_change { course.reload.sequence_number }
    expect(result.errors.first.code).to eq :no_exercises
  end
end

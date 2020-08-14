require 'rails_helper'

RSpec.describe Tasks::FetchAssignmentPes, type: :routine do
  context 'with some existing tasks' do
    before(:all) do
      DatabaseCleaner.start

      task_plan_1 = FactoryBot.create(:tasked_task_plan)
      @ecosystem_1 = task_plan_1.ecosystem
      @book_1 = @ecosystem_1.books.first
      @chapter_1 = @book_1.chapters.first
      @page_1 = @chapter_1.pages.first
      @exercise_1 = Content::Models::Exercise.joins(:page).find_by(page: { id: @page_1.id })

      task_plan_2 = FactoryBot.create(:tasked_task_plan)
      @ecosystem_2 = task_plan_2.ecosystem
      @book_2 = @ecosystem_2.books.first
      @chapter_2 = @book_2.chapters.first
      @page_2 = @chapter_2.pages.first
      @exercise_2 = Content::Models::Exercise.joins(:page).find_by(page: { id: @page_2.id })

      @task = task_plan_1.tasks.first
      @tasked_exercise = @task.tasked_exercises.first

      @student = @task.taskings.first.role.student
      @period = @student.period
      @course = @period.course

      @preparation_uuid = SecureRandom.uuid

      @max_num_exercises = 5

      @excluded_exercises = 3.times.map { FactoryBot.create :content_exercise }
      @previous_globally_excluded_exercises = Settings::Exercises.excluded_ids
      Settings::Exercises.excluded_ids = @excluded_exercises.map(&:uid).join(', ')
    end

    after(:all) do
      Settings::Exercises.excluded_ids = @previous_globally_excluded_exercises

      DatabaseCleaner.clean
    end

    let(:expected_exercises) do
      Set.new Content::Models::Exercise.where(content_page_id: @task.core_page_ids).to_a
    end

    it 'returns exercises from the expected pages' do
      outs = described_class.call(task: @task, max_num_exercises: @max_num_exercises).outputs
      exercises = outs.exercises
      expect(exercises).not_to be_empty
      exercises.each { |exercise| expect(expected_exercises).to include exercise }

      expected_exercise_uids_set = Set.new expected_exercises.map(&:uid)
      outs.initially_eligible_exercise_uids.each do |uid|
        expect(expected_exercise_uids_set).to include(uid)
      end
      expect(outs.admin_excluded_uids).to eq []
      expect(outs.course_excluded_uids).to eq []
      expect(outs.role_excluded_uids).to be_a(Array)
    end
  end
end

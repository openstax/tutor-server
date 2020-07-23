require 'rails_helper'

RSpec.describe Tasks::FetchAssignmentSpes, type: :routine do
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
      exercises = described_class[task: @task, max_num_exercises: @max_num_exercises]
      expect(exercises).not_to be_empty
      exercises.each do |exercise|
        expect(expected_exercises).to include exercise
      end
    end
  end

  context 'with many existing tasks' do
    before(:all)  do
      DatabaseCleaner.start

      student = FactoryBot.create :course_membership_student
      period = student.period
      @course = period.course
      book = FactoryBot.create :content_book, :standard_contents_2, ecosystem: @course.ecosystem

      assistant = Tasks::Models::Assistant.find_by(
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      ) || FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )

      book.pages.each do |page|
        # Make sure all pages have at least 8 unused reading dynamic exercises
        # to avoid dropping spaced practice due to insufficient exercises
        page.reading_dynamic_exercise_ids.concat(
          8.times.map { FactoryBot.create(:content_exercise, page: page).id }
        )
        page.save!
      end

      task_plans = book.pages.map do |page|
        FactoryBot.create(
          :tasks_task_plan,
          course: @course,
          target: period,
          settings: { 'page_ids' => [ page.id.to_s ] },
          assistant: assistant
        ).tap { |task_plan| DistributeTasks.call task_plan: task_plan }
      end

      current_time = @course.time_zone.now

      @page_1_exercise_uuids = book.pages.first.exercises.map(&:uuid)
      task_plan_1 = task_plans.first
      task_plan_1.tasking_plans.each do |tasking_plan|
        tasking_plan.update_attribute :due_at, current_time + 1.hour
      end
      @task_1 = task_plan_1.tasks.first

      @page_2_exercise_uuids = book.pages.second.exercises.map(&:uuid)
      task_plan_2 = task_plans.second
      task_plan_2.tasking_plans.each do |tasking_plan|
        tasking_plan.update_attribute :due_at, current_time + 1.day
      end
      @task_2 = task_plan_2.tasks.first

      @page_3_exercise_uuids = book.pages.third.exercises.map(&:uuid)
      task_plan_3 = task_plans.third
      task_plan_3.tasking_plans.each do |tasking_plan|
        tasking_plan.update_attribute :due_at, current_time + 1.week
      end
      @task_3 = task_plan_3.tasks.first

      @page_4_exercise_uuids = book.pages.fourth.exercises.map(&:uuid)
      task_plan_4 = task_plans.fourth
      task_plan_4.tasking_plans.each do |tasking_plan|
        tasking_plan.update_attribute :due_at, current_time + 1.month
      end
      @task_4 = task_plan_4.tasks.first

      AddUserAsPeriodStudent.call user: FactoryBot.create(:user_profile), period: period
    end
    after(:all)   { DatabaseCleaner.clean }

    before do
      @course.reload

      @task_1.reload
      @task_2.reload
      @task_3.reload
      @task_4.reload
    end

    context 'when no assignments are past-due' do
      context 'when worked in order' do
        it 'returns spaced practice exercises from the correct sections' do
          task_1_spe_uuids = described_class[task: @task_1, max_num_exercises: 3].map(&:uuid)
          expect(task_1_spe_uuids.size).to eq 3
          task_1_spe_uuids.each do |exercise_uuid|
            expect(@page_1_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_1, is_correct: [ true, false ].sample

          task_2_spe_uuids = described_class[task: @task_2, max_num_exercises: 3].map(&:uuid)
          expect(task_2_spe_uuids.size).to eq 3
          expect(@page_1_exercise_uuids).to include(task_2_spe_uuids.first)
          task_2_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_2_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_2, is_correct: [ true, false ].sample

          task_3_spe_uuids = described_class[task: @task_3, max_num_exercises: 3].map(&:uuid)
          expect(task_3_spe_uuids.size).to eq 3
          expect(@page_2_exercise_uuids).to include(task_3_spe_uuids.first)
          task_3_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_3_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_3, is_correct: [ true, false ].sample

          task_4_spe_uuids = described_class[task: @task_4, max_num_exercises: 3].map(&:uuid)
          expect(task_4_spe_uuids.size).to eq 3
          expect(@page_3_exercise_uuids).to include(task_4_spe_uuids.first)
          expect(@page_1_exercise_uuids).to include(task_4_spe_uuids.second)
          expect(@page_4_exercise_uuids).to include(task_4_spe_uuids.third)
        end
      end

      context 'when worked in reverse order' do
        it 'returns spaced practice exercises from the correct sections' do
          task_4_spe_uuids = described_class[task: @task_4, max_num_exercises: 3].map(&:uuid)
          expect(task_4_spe_uuids.size).to eq 3
          task_4_spe_uuids.each do |exercise_uuid|
            expect(@page_4_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_4, is_correct: [ true, false ].sample

          task_3_spe_uuids = described_class[task: @task_3, max_num_exercises: 3].map(&:uuid)
          expect(task_3_spe_uuids.size).to eq 3
          expect(@page_4_exercise_uuids).to include(task_3_spe_uuids.first)
          task_3_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_3_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_3, is_correct: [ true, false ].sample

          task_2_spe_uuids = described_class[task: @task_2, max_num_exercises: 3].map(&:uuid)
          expect(task_2_spe_uuids.size).to eq 3
          expect(@page_3_exercise_uuids).to include(task_2_spe_uuids.first)
          task_2_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_2_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_2, is_correct: [ true, false ].sample

          task_1_spe_uuids = described_class[task: @task_1, max_num_exercises: 3].map(&:uuid)
          expect(task_1_spe_uuids.size).to eq 3
          expect(@page_2_exercise_uuids).to include(task_1_spe_uuids.first)
          expect(@page_4_exercise_uuids).to include(task_1_spe_uuids.second)
          expect(@page_1_exercise_uuids).to include(task_1_spe_uuids.third)
        end
      end
    end

    context 'when an assignment is past-due' do
      before { @course.update_attribute :timezone, 'US/Eastern' }

      context 'when worked in order' do
        it 'returns spaced practice exercises from the correct sections' do
          task_2_spe_uuids = described_class[task: @task_2, max_num_exercises: 3].map(&:uuid)
          expect(task_2_spe_uuids.size).to eq 3
          expect(@page_1_exercise_uuids).to include(task_2_spe_uuids.first)
          task_2_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_2_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_2, is_correct: [ true, false ].sample

          task_3_spe_uuids = described_class[task: @task_3, max_num_exercises: 3].map(&:uuid)
          expect(task_3_spe_uuids.size).to eq 3
          expect(@page_2_exercise_uuids).to include(task_3_spe_uuids.first)
          task_3_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_3_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_3, is_correct: [ true, false ].sample

          task_4_spe_uuids = described_class[task: @task_4, max_num_exercises: 3].map(&:uuid)
          expect(task_4_spe_uuids.size).to eq 3
          expect(@page_3_exercise_uuids).to include(task_4_spe_uuids.first)
          expect(@page_1_exercise_uuids).to include(task_4_spe_uuids.second)
          expect(@page_4_exercise_uuids).to include(task_4_spe_uuids.third)
        end
      end

      context 'when worked in reverse order' do
        it 'returns spaced practice exercises from the correct sections' do
          task_4_spe_uuids = described_class[task: @task_4, max_num_exercises: 3].map(&:uuid)
          expect(task_4_spe_uuids.size).to eq 3
          expect(@page_1_exercise_uuids).to include(task_4_spe_uuids.first)
          task_4_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_4_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_4, is_correct: [ true, false ].sample

          task_3_spe_uuids = described_class[task: @task_3, max_num_exercises: 3].map(&:uuid)
          expect(task_3_spe_uuids.size).to eq 3
          expect(@page_4_exercise_uuids).to include(task_3_spe_uuids.first)
          task_3_spe_uuids[1..-1].each do |exercise_uuid|
            expect(@page_3_exercise_uuids).to include(exercise_uuid)
          end

          Preview::WorkTask.call task: @task_3, is_correct: [ true, false ].sample

          task_2_spe_uuids = described_class[task: @task_2, max_num_exercises: 3].map(&:uuid)
          expect(task_2_spe_uuids.size).to eq 3
          expect(@page_3_exercise_uuids).to include(task_2_spe_uuids.first)
          expect(@page_1_exercise_uuids).to include(task_2_spe_uuids.second)
          expect(@page_2_exercise_uuids).to include(task_2_spe_uuids.third)
        end
      end
    end
  end
end

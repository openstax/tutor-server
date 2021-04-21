require 'rails_helper'

RSpec.describe Tasks::FetchPracticeWorstAreasExercises, type: :routine do
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

      @page_uuids = [ @page_1, @page_2 ].map(&:uuid).uniq
      @pages = @ecosystem_1.pages.where(uuid: @page_1.uuid) +
               @ecosystem_2.pages.where(uuid: @page_2.uuid)

      @task = task_plan_1.tasks.first
      @tasked_exercise = @task.tasked_exercises.first

      @student = @task.taskings.first.role.student
      @period = @student.period
      @course = @period.course

      @teacher = FactoryBot.create :course_membership_teacher, course: @course

      @preparation_uuid = SecureRandom.uuid

      @max_num_exercises = 5

      @teacher_exercises = 10.times.map do
        FactoryBot.create :content_exercise, page: @pages.sample, profile: @teacher.role.profile
      end
      @excluded_exercises = 10.times.map do
        FactoryBot.create :content_exercise, page: @pages.sample
      end
      @previous_globally_excluded_exercises = Settings::Exercises.excluded_ids
      Settings::Exercises.excluded_ids = @excluded_exercises.map(&:uid).join(', ')

      @all_exercises = @pages.flat_map(&:exercises)
      @excluded_exercises.each { |exercise| expect(@all_exercises).to include exercise }
      @valid_exercises = @pages.flat_map(&:exercises) - @excluded_exercises

      @page_uuids.each do |page_uuid|
        FactoryBot.create :ratings_role_book_part, role: @student.role,
                                                   is_page: true,
                                                   book_part_uuid: page_uuid
      end
    end

    after(:all) do
      Settings::Exercises.excluded_ids = @previous_globally_excluded_exercises

      DatabaseCleaner.clean
    end

    it 'returns the expected response' do
      exercises = described_class[student: @student, max_num_exercises: @max_num_exercises]
      expect(exercises.size).to eq 5
      exercises.each { |exercise| expect(@valid_exercises).to include exercise }
    end
  end
end

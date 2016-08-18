require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetConceptCoach, type: :routine, speed: :medium do

  CORE_EXERCISES_COUNT = Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT

  def spaced_exercises_count(index)
    Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
      .select{ |k_ago, ex_count| (k_ago == :random && index >= 4) || \
                                 (k_ago != :random && k_ago <= index) }
      .map{ |k_ago, ex_count| ex_count }.reduce(0, :+)
  end

  def exercises_count(index)
    CORE_EXERCISES_COUNT + spaced_exercises_count(index)
  end

  before(:all) do
    ecosystem = VCR.use_cassette('GetConceptCoach/with_book', VCR_OPTS) do
      OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/') do
        FetchAndImportBookAndCreateEcosystem[book_cnx_id: 'f10533ca-f803-490d-b935-88899941197f']
      end
    end

    @book = ecosystem.books.first

    page_model_1 = Content::Models::Page.find_by(title: 'Sample module 1')
    page_model_2 = Content::Models::Page.find_by(title: 'The Science of Biology')
    page_model_3 = Content::Models::Page.find_by(title: 'Sample module 2')
    page_model_4 = Content::Models::Page.find_by(
      title: 'Atoms, Isotopes, Ions, and Molecules: The Building Blocks'
    )

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
    @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)
    @page_4 = Content::Page.new(strategy: page_model_4.reload.wrap)

    period_model = FactoryGirl.create(:course_membership_period)
    period = CourseMembership::Period.new(strategy: period_model.wrap)
    @course = period.course
    @course.profile.update_attribute(:is_concept_coach, true)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]

    @user_1 = FactoryGirl.create(:user)
    @user_2 = FactoryGirl.create(:user)

    AddUserAsPeriodStudent[user: @user_1, period: period]
    AddUserAsPeriodStudent[user: @user_2, period: period]
  end

  context 'no existing task' do
    it 'creates a new Task' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ] }.to change{ Tasks::Models::Task.count }.by(1)
      expect(task.task_steps.size).to eq exercises_count(0)
      task.task_steps.each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

    it 'creates a new ConceptCoachTask' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ] }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      cc_task = Tasks::Models::ConceptCoachTask.order(:created_at).last
      expect(cc_task.task).to eq task
    end

    it 'returns an error if the book is invalid' do
      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: 'invalid', cnx_page_id: @page_1.uuid
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:invalid_book]
      expect(result.outputs.valid_book_urls).to eq [@book.url]
    end

    it 'returns an error if the page is invalid' do
      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: 'invalid'
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:invalid_page]
      expect(result.outputs.valid_book_urls).to eq [@book.url]
    end

    it 'does not include non-cc courses' do
      @course.profile.update_attribute(:is_concept_coach, false)

      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:not_a_cc_student]
    end
  end

  context 'existing task' do
    let!(:existing_task) { described_class[user: @user_1,
                                           cnx_book_id: @book.uuid,
                                           cnx_page_id: @page_1.uuid] }

    it 'should not create a new task for the same user and page' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ] }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(task).to eq existing_task
    end

    it 'should create a new task for a different user' do
      task = nil
      expect{ task = described_class[
        user: @user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ] }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      expect(task).not_to eq existing_task
      expect(task.task_steps.size).to eq exercises_count(0)
      task.task_steps.each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

it 'should create a new task for a different page and properly assign spaced practice' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ] }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      expect(task).not_to eq existing_task
      expect(task.task_steps.size).to eq exercises_count(1)
      task.task_steps.first(CORE_EXERCISES_COUNT).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_2.id
      end
      task.task_steps.last(spaced_exercises_count(1)).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

    it 'should assign spaced practice according to the k-ago map' do
      task_pages = [@page_1, @page_2, @page_3, @page_4]
      tasks = task_pages.map do |page|
        described_class[
          user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: page.uuid
        ]
      end

      tasks.each_with_index do |task, ii|
        page = task_pages[ii]

        expected_core_exercises = [CORE_EXERCISES_COUNT, page.exercises.size].min
        expected_num_exercises = expected_core_exercises + spaced_exercises_count(ii)

        expect(task.tasked_exercises.count).to eq expected_num_exercises

        task.tasked_exercises.first(expected_core_exercises).each do |te|
          expect(te.exercise.page.id).to eq page.id
        end
      end

      forbidden_random_ks = Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                              .map(&:first).select{ |k_ago| k_ago != :random }.uniq

      tasks.slice(1..-1).each_with_index do |task, ii|
        task_index = ii + 1
        spaced_page_ids = task.tasked_exercises
                              .last(spaced_exercises_count(task_index)).map do |te|
          te.exercise.page.id
        end
        available_random_page_ids = task_pages.slice(0..ii).map(&:id)
        forbidden_random_ks.each do |forbidden_random_k|
          available_random_page_ids.delete_at(-forbidden_random_k)
        end

        Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP.each do |k_ago, count|
          current_page_ids = spaced_page_ids.shift(count)
          current_page_ids.each do |page_id|
            if k_ago == :random
              expect(available_random_page_ids).to include(page_id)
            else
              expect(page_id).to eq task_pages[task_index - k_ago].id
            end
          end
        end
      end
    end

    it 'returns an error if the book is invalid' do
      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: 'invalid', cnx_page_id: @page_1.uuid
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:invalid_book]
      expect(result.outputs.valid_book_urls).to eq [@book.url]
    end

    it 'returns an error if the page is invalid' do
      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: 'invalid'
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:invalid_page]
      expect(result.outputs.valid_book_urls).to eq [@book.url]
    end

    it 'returns an error if the page has no exercises' do
      chapter_model = Content::Models::Chapter.find(@book.chapters.first.id)
      page = FactoryGirl.create :content_page, chapter: chapter_model
      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: page.uuid
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:page_has_no_exercises]
      expect(result.outputs.valid_book_urls).to eq [@book.url]
    end
  end

end

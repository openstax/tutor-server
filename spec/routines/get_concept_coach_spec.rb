require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetConceptCoach, type: :routine do

  CORE_EXERCISES_COUNT = Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT
  SPACED_EXERCISES_COUNT = Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                             .map{ |k_ago, ex_count| ex_count }.reduce(:+)

  before(:all) do
    DatabaseCleaner.start

    ecosystem = VCR.use_cassette('GetConceptCoach/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    @book = ecosystem.books.first

    page_model_1 = Content::Models::Page.find_by(title: 'Acceleration')
    page_model_2 = Content::Models::Page.find_by(title: 'Representing Acceleration with Equations and Graphs')
    page_model_3 = Content::Models::Page.find_by(title: 'Force')
    page_model_4 = Content::Models::Page.find_by(title: 'Newton\'s First Law of Motion: Inertia')
    page_model_5 = Content::Models::Page.find_by(title: 'Newton\'s Second Law of Motion')
    page_model_6 = Content::Models::Page.find_by(title: 'Newton\'s Third Law of Motion')

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
    @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)
    @page_4 = Content::Page.new(strategy: page_model_4.reload.wrap)
    @page_5 = Content::Page.new(strategy: page_model_5.reload.wrap)
    @page_6 = Content::Page.new(strategy: page_model_6.reload.wrap)

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

  after(:all) do
    DatabaseCleaner.clean
  end

  context 'no existing task' do
    it 'creates a new Task' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task }.to change{ Tasks::Models::Task.count }.by(1)
      expect(task.task_steps.size).to eq CORE_EXERCISES_COUNT
      task.task_steps.each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

    it 'creates a new ConceptCoachTask' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      cc_task = Tasks::Models::ConceptCoachTask.order(:created_at).last
      expect(cc_task.task).to eq task.entity_task
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
                                           cnx_page_id: @page_1.uuid].task }

    it 'should not create a new task for the same user and page' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(task).to eq existing_task
    end

    it 'should create a new task for a different user' do
      task = nil
      expect{ task = described_class[
        user: @user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      expect(task).not_to eq existing_task
      expect(task.task_steps.size).to eq CORE_EXERCISES_COUNT
      task.task_steps.each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

it 'should create a new task for a different page and properly assign spaced practice' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      expect(task).not_to eq existing_task
      expect(task.task_steps.size).to eq CORE_EXERCISES_COUNT + SPACED_EXERCISES_COUNT
      task.task_steps.first(CORE_EXERCISES_COUNT).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_2.id
      end
      task.task_steps.last(SPACED_EXERCISES_COUNT).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

    it 'should assign spaced practice according to the k-ago map' do
      task_pages = [@page_1, @page_2, @page_3, @page_4, @page_5, @page_6]
      tasks = task_pages.map do |page|
        described_class[
          user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: page.uuid
        ].task
      end

      tasks.each_with_index do |task, ii|
        page = task_pages[ii]

        expected_num_exercises = ii == 0 ? CORE_EXERCISES_COUNT : \
                                           CORE_EXERCISES_COUNT + SPACED_EXERCISES_COUNT

        expect(task.tasked_exercises.count).to eq expected_num_exercises

        task.tasked_exercises.first(CORE_EXERCISES_COUNT).each do |te|
          expect(te.exercise.page.id).to eq page.id
        end
      end

      tasks.slice(1..-1).each_with_index do |task, ii|
        task_index = ii + 1
        spaced_page_ids = task.tasked_exercises.last(SPACED_EXERCISES_COUNT).map do |te|
          te.exercise.page.id
        end
        available_random_page_ids = task_pages.slice(0..ii).map(&:id)

        Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP.each do |k_ago, count|
          current_page_ids = spaced_page_ids.shift(count)
          current_page_ids.each do |page_id|
            if k_ago.nil? || task_index - k_ago < 0
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
      page = FactoryGirl.create :content_page, chapter: @book.chapters.first
      result = nil
      expect{ result = described_class.call(
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: page.uuid
      ) }.not_to change{ Tasks::Models::ConceptCoachTask.count }
      expect(result.errors.map(&:code)).to eq [:page_has_no_exercises]
      expect(result.outputs.valid_book_urls).to eq [@book.url]
    end
  end

end

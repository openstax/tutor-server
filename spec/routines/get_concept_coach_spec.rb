require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetConceptCoach, type: :routine do

  before(:all) do
    DatabaseCleaner.start

    ecosystem = VCR.use_cassette('GetConceptCoach/with_book', VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    end

    @book = ecosystem.books.first

    page_model_1 = Content::Models::Page.find_by(title: 'Force')
    page_model_2 = Content::Models::Page.find_by(title: 'Newton\'s First Law of Motion: Inertia')
    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)

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
      expect(task.task_steps.size).to eq Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT
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
      expect(task.task_steps.size).to eq Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT
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
      expect(task.task_steps.size).to eq Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT + \
                                         Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                                           .map{ |k_ago, ex_count| ex_count }.reduce(:+)
      task.task_steps.first(
        Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT
      ).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_2.id
      end
      task.task_steps.last(
        Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
          .map{ |k_ago, ex_count| ex_count }.reduce(:+)
      ).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
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
  end

end

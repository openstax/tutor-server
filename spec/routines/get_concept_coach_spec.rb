require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetConceptCoach, type: :routine do

  before(:all) do
    DatabaseCleaner.start

    chapter = FactoryGirl.create :content_chapter
    cnx_page_1 = OpenStax::Cnx::V1::Page.new(id: '95e61258-2faf-41d4-af92-f62e1414175a',
                                             title: 'Force')
    cnx_page_2 = OpenStax::Cnx::V1::Page.new(id: '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
                                             title: "Newton's First Law of Motion: Inertia")
    book_location_1 = [4, 1]
    book_location_2 = [4, 2]

    page_model_1, page_model_2 = VCR.use_cassette('GetConceptCoach/with_pages', VCR_OPTS) do
      [Content::Routines::ImportPage[chapter: chapter,
                                     cnx_page: cnx_page_1,
                                     book_location: book_location_1],
       Content::Routines::ImportPage[chapter: chapter,
                                     cnx_page: cnx_page_2,
                                     book_location: book_location_2]]
    end

    @book = chapter.book
    Content::Routines::PopulateExercisePools[book: @book]

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)

    ecosystem_model = @book.ecosystem
    ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)

    period_model = FactoryGirl.create(:course_membership_period)
    period = CourseMembership::Period.new(strategy: period_model.wrap)

    AddEcosystemToCourse[ecosystem: ecosystem, course: period.course]

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
      expect(task.task_steps.size).to eq described_class::CORE_EXERCISES_COUNT
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
      expect(task.task_steps.size).to eq described_class::CORE_EXERCISES_COUNT
      task.task_steps.each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end

    it 'should create a new task for a different page' do
      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      expect(task).not_to eq existing_task
      expect(task.task_steps.size).to eq described_class::CORE_EXERCISES_COUNT
      task.task_steps.each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_2.id
      end
    end

    it 'should properly assign spaced practice' do
      existing_task.task_steps.first.complete.save!
      existing_task.task_steps.second.complete.save!

      task = nil
      expect{ task = described_class[
        user: @user_1, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task }.to change{ Tasks::Models::ConceptCoachTask.count }.by(1)
      expect(task).not_to eq existing_task
      expect(task.task_steps.size).to eq described_class::CORE_EXERCISES_COUNT + \
                                         described_class::SPACED_EXERCISES_COUNT
      task.task_steps.first(described_class::CORE_EXERCISES_COUNT).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_2.id
      end
      task.task_steps.last(described_class::SPACED_EXERCISES_COUNT).each do |task_step|
        expect(task_step.tasked.exercise.page.id).to eq @page_1.id
      end
    end
  end

end

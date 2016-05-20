require 'rails_helper'

RSpec.describe Tasks::Models::TaskPlan, type: :model do
  subject(:task_plan) { FactoryGirl.create :tasks_task_plan }

  let!(:new_task) { FactoryGirl.build :tasks_task, opens_at: Time.current.yesterday }

  it { is_expected.to belong_to(:assistant) }
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:assistant) }
  it { is_expected.to validate_presence_of(:ecosystem) }
  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:tasking_plans) }

  it "validates settings against the assistant's schema" do
    book = FactoryGirl.create :content_book, ecosystem: task_plan.ecosystem
    chapter = FactoryGirl.create :content_chapter, book: book
    page = FactoryGirl.create :content_page, chapter: chapter
    exercise = FactoryGirl.create :content_exercise, page: page
    task_plan.reload

    task_plan.assistant = FactoryGirl.create(
      :tasks_assistant, code_class_name: '::Tasks::Assistants::IReadingAssistant'
    )
    task_plan.settings = { exercise_ids: [exercise.id.to_s] }
    expect(task_plan).not_to be_valid

    task_plan.settings = { page_ids: [] }
    expect(task_plan).not_to be_valid

    task_plan.settings = { page_ids: [page.id.to_s] }
    expect(task_plan).to be_valid
  end

  it "requires that any exercise_ids or page_ids be in the task_plan's ecosystem" do
    book = FactoryGirl.create :content_book, ecosystem: task_plan.ecosystem
    chapter = FactoryGirl.create :content_chapter, book: book
    page = FactoryGirl.create :content_page, chapter: chapter
    exercise = FactoryGirl.create :content_exercise, page: page
    task_plan.reload

    task_plan.assistant = FactoryGirl.create(
      :tasks_assistant, code_class_name: '::Tasks::Assistants::HomeworkAssistant'
    )
    task_plan.settings = {
      page_ids: ["1", "2"], exercise_ids: ["1", "2"], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: [page.id.to_s], exercise_ids: ["1", "2"], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: ["1", "2"], exercise_ids: [exercise.id.to_s], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: [page.id.to_s], exercise_ids: [exercise.id.to_s], exercises_count_dynamic: 2
    }
    expect(task_plan).to be_valid
  end

  it 'allows name and description to be updated after a task is open' do
    task_plan.tasks << new_task
    task_plan.title = 'New Title'
    task_plan.description = 'New description!'
    expect(task_plan).to be_valid
  end

  it 'will not allow other fields to be updated after a task is open' do
    task_plan.tasks << new_task
    task_plan.settings = { due_at: Time.current.tomorrow }
    expect(task_plan).not_to be_valid
  end

  it 'requires due_at to be in the future when publishing' do
    task_plan.is_publish_requested = true
    expect(task_plan).to be_valid

    task_plan.tasking_plans.first.due_at = Time.current.yesterday
    expect(task_plan).to_not be_valid
  end

  it 'cannot be deleted if it has open tasks' do
    expect(task_plan.destroy).to eq task_plan
    expect(task_plan.destroyed?).to eq true

    new_task.save!
    new_task.reload
    expect(new_task.task_plan.destroy).to eq false
    expect(new_task.task_plan.destroyed?).to eq false
    expect(new_task.task_plan.errors).to include(:base)
    expect(new_task.task_plan.errors.messages).to(
      include(:base => ["cannot be deleted after it is open"])
    )
  end
end

require 'rails_helper'

RSpec.describe Tasks::Models::TaskPlan, type: :model do
  subject(:task_plan) { FactoryGirl.create :tasks_task_plan }

  let(:new_task)      { FactoryGirl.build :tasks_task, opens_at: Time.current.yesterday }

  it { is_expected.to belong_to(:assistant) }
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to belong_to(:cloned_from) }

  it { is_expected.to have_many(:tasking_plans) }
  it { is_expected.to have_many(:tasks) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:assistant) }
  it { is_expected.to validate_presence_of(:owner) }

  it do
    # shoulda-matchers fails to properly remove the associated records
    subject.tasking_plans.delete_all :delete_all

    is_expected.to validate_presence_of(:tasking_plans)
  end

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

  it "automatically infers the ecosystem from the settings or owner" do
    ecosystem = task_plan.ecosystem
    book = FactoryGirl.create :content_book, ecosystem: ecosystem
    chapter = FactoryGirl.create :content_chapter, book: book
    page = FactoryGirl.create :content_page, chapter: chapter
    exercise = FactoryGirl.create :content_exercise, page: page

    task_plan.owner.course_ecosystems.delete_all :delete_all
    task_plan.ecosystem = nil
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to be_nil

    task_plan.settings = { exercise_ids: [exercise.id.to_s] }
    expect(task_plan).to be_valid
    expect(task_plan.ecosystem).to eq ecosystem

    task_plan.settings = {}
    task_plan.ecosystem = nil
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to be_nil

    task_plan.settings = { page_ids: [page.id.to_s] }
    expect(task_plan).to be_valid
    expect(task_plan.ecosystem).to eq ecosystem

    task_plan.settings = {}
    task_plan.ecosystem = nil
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to be_nil

    task_plan.owner.ecosystems << ecosystem
    expect(task_plan).to be_valid
    expect(task_plan.ecosystem).to eq ecosystem
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
      page_ids: ['1', '2'], exercise_ids: ['1', '2'], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: [page.id.to_s], exercise_ids: ['1', '2'], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: ['1', '2'], exercise_ids: [exercise.id.to_s], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: [page.id.to_s], exercise_ids: [exercise.id.to_s], exercises_count_dynamic: 2
    }
    expect(task_plan).to be_valid
  end

  it 'allows name, description and is_feedback_immediate to be updated after a task is open' do
    task_plan.tasks << new_task
    task_plan.title = 'New Title'
    task_plan.description = 'New description!'
    task_plan.is_feedback_immediate = false
    expect(task_plan).to be_valid
  end

  it 'requires all tasking_plan due_ats to be in the future when publishing' do
    task_plan.is_publish_requested = true
    expect(task_plan).to be_valid

    task_plan.tasking_plans.first.due_at = Time.current.yesterday
    expect(task_plan).to_not be_valid
  end

  it 'trims title and description fields' do
    task_plan.title = " hi\n\n\r\n "
    task_plan.description = " \tthere\t "
    task_plan.save
    expect(task_plan.title).to eq 'hi'
    expect(task_plan.description).to eq 'there'
  end

  it 'knows its publish job' do
    uuid = SecureRandom.uuid
    job = double('Job')

    expect(Jobba).to receive(:find).with(uuid).and_return(job)
    task_plan.publish_job_uuid = uuid
    expect(task_plan.publish_job).to eq job
  end

  it "automatically sets its ecosystem to the original's if cloned_from is specified" do
    clone = FactoryGirl.build :tasks_task_plan, cloned_from: task_plan
    clone.ecosystem = nil
    expect(clone.valid?).to eq true
    expect(clone.ecosystem).to eq task_plan.ecosystem
  end

  it "automatically sets its ecosystem to the owner's if cloned_from is not specified" do
    course = task_plan.owner
    ecosystem_model = FactoryGirl.create :content_ecosystem
    ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)
    AddEcosystemToCourse[ecosystem: ecosystem, course: course]
    new_task_plan = FactoryGirl.build :tasks_task_plan, owner: course
    new_task_plan.ecosystem = nil
    expect(new_task_plan.valid?).to eq true
    expect(new_task_plan.ecosystem).to eq ecosystem_model
  end

  context 'with tasks assigned to students' do
    let(:teacher_student_role) { FactoryGirl.create :entity_role, role_type: :teacher_student }
    let(:teacher_student_task) do
      FactoryGirl.create :tasks_task, task_plan: task_plan, tasked_to: [teacher_student_role]
    end

    let(:student_role) { FactoryGirl.create :entity_role, role_type: :student }
    let(:student_task) do
      FactoryGirl.create :tasks_task, task_plan: task_plan, tasked_to: [student_role]
    end

    it 'knows if tasks are available to students' do
      expect(task_plan.out_to_students?).to eq false

      teacher_student_task
      expect(task_plan.reload.out_to_students?).to eq false

      student_task
      expect(task_plan.reload.out_to_students?).to eq true

      future_time = Time.now.utc + 1.week
      student_task.update_attribute :opens_at_ntz, future_time
      expect(task_plan.reload.out_to_students?).to eq false
      expect(task_plan.reload.out_to_students?(current_time: future_time + 2.days)).to eq true
    end

    it 'can still be deleted and restored after tasks are available to students' do
      expect(task_plan.withdrawn?).to eq false

      student_task
      expect(task_plan.reload.out_to_students?).to eq true

      task_plan.destroy
      expect(task_plan.withdrawn?).to eq true

      task_plan.restore
      expect(task_plan.withdrawn?).to eq false
    end

    it 'will not allow other fields to be updated after tasks are available to students' do
      task_plan.reload.settings = { due_at: Time.current.tomorrow }
      expect(task_plan).to be_valid

      student_task

      task_plan.reload.settings = { due_at: Time.current.tomorrow }
      expect(task_plan).not_to be_valid
    end
  end

end

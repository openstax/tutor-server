require 'rails_helper'

RSpec.describe Tasks::Models::TaskPlan, type: :model do
  subject(:task_plan) { FactoryBot.create :tasks_task_plan }

  let(:new_task)  { FactoryBot.build :tasks_task, opens_at: Time.current.yesterday }
  let(:ecosystem) { task_plan.ecosystem }
  let(:book)      { FactoryBot.create :content_book, ecosystem: ecosystem }
  let(:page)      { FactoryBot.create :content_page, book: book }
  let(:exercise)  { FactoryBot.create :content_exercise, page: page }

  it { is_expected.to belong_to(:assistant) }
  it { is_expected.to belong_to(:course) }

  it { is_expected.to belong_to(:cloned_from).optional }

  it do
    # grading_template is not optional for reading/homework
    task_plan.type = 'external'

    is_expected.to belong_to(:grading_template).optional
  end

  it { is_expected.to have_many(:tasking_plans) }
  it { is_expected.to have_many(:tasks) }
  it { is_expected.to have_many(:extensions) }
  it { is_expected.to have_many(:dropped_questions) }

  it { is_expected.to validate_presence_of(:title) }

  it 'requires at least one tasking_plan' do
    expect(task_plan).to be_valid

    task_plan.tasking_plans.destroy_all
    expect(task_plan).not_to be_valid
  end

  it "validates settings are present when publishing" do
    expect(task_plan).to be_valid
#    task_plan.is_publish_requested = true
  end

  it "validates settings against the assistant's schema" do
    task_plan.reload

    task_plan.assistant = FactoryBot.create(
      :tasks_assistant, code_class_name: '::Tasks::Assistants::IReadingAssistant'
    )
    task_plan.settings = { page_ids: [] }
    expect(task_plan).to be_valid
    task_plan.is_publish_requested = true
    expect(task_plan).not_to be_valid
    expect(task_plan.errors.full_messages.first).to include 'must have at least one page'

    task_plan.is_publish_requested = false
    task_plan.type = 'homework'
    task_plan.assistant = FactoryBot.create(
      :tasks_assistant, code_class_name: '::Tasks::Assistants::HomeworkAssistant'
    )
    task_plan.settings = {
      exercises_count_dynamic: 1,
      exercises: []
    }
    task_plan.grading_template = FactoryBot.create(
      :tasks_grading_template, task_plan_type: :homework, course: task_plan.course
    )
    expect(task_plan).to be_valid
    task_plan.is_publish_requested = true
    expect(task_plan).not_to be_valid
    expect(task_plan.errors.full_messages.first).to include 'must have at least one exercise'
  end

  it 'automatically infers the ecosystem from the settings or course' do
    task_plan.course.course_ecosystems.delete_all :delete_all
    task_plan.settings = {
      exercises: [ { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions } ]
    }
    task_plan.ecosystem = nil
    expect(task_plan.ecosystem).to be_nil
    # Not valid because the course does not have the ecosystem
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to eq ecosystem

    task_plan.settings = {}
    task_plan.ecosystem = nil
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to be_nil

    task_plan.settings = { page_ids: [ page.id.to_s ] }
    # Not valid because the course does not have the ecosystem
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to eq ecosystem

    task_plan.settings = {}
    task_plan.ecosystem = nil
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).to be_nil

    AddEcosystemToCourse.call(course: task_plan.course, ecosystem: ecosystem)
    expect(task_plan).to be_valid
    expect(task_plan.ecosystem).to eq ecosystem
  end

  it "requires that any exercises or page_ids be in the task_plan's ecosystem" do
    task_plan.reload

    task_plan.assistant = FactoryBot.create(
      :tasks_assistant, code_class_name: '::Tasks::Assistants::HomeworkAssistant'
    )
    task_plan.settings = {
      page_ids: ['1', '2'], exercises: [
        { id: '1', points: [ 1 ] }, { id: '2', points: [ 1 ] }
      ], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: [page.id.to_s], exercises: [
        { id: '111', points: [ 1 ] }, { id: '2222', points: [ 1 ] }
      ], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid
    expect(task_plan.ecosystem).not_to be_nil
    task_plan.settings = {
      page_ids: ['333', '222'], exercises: [
        { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
      ], exercises_count_dynamic: 2
    }
    expect(task_plan).not_to be_valid

    task_plan.settings = {
      page_ids: [page.id.to_s], exercises: [
        { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
      ], exercises_count_dynamic: 2
    }
    expect(task_plan).to be_valid
  end

  it 'validates that it has a grading template, if it is a reading or homework' do
    expect(task_plan).to be_valid

    task_plan.grading_template = nil
    expect(task_plan).not_to be_valid

    task_plan.type = 'homework'
    task_plan.settings['exercises'] = [ { 'id' => '1', 'points' => [ 1 ] } ]
    expect(task_plan).not_to be_valid

    task_plan.type = 'external'
    task_plan.settings = { 'external_url' => 'https://www.example.com' }
    expect(task_plan).to be_valid
  end

  it 'validates that the grading template belongs to the same course' do
    expect(task_plan).to be_valid
    task_plan.grading_template = FactoryBot.create :tasks_grading_template
    expect(task_plan).not_to be_valid
  end

  it 'validates that the grading template is for the correct task_plan type' do
    expect(task_plan).to be_valid

    grading_template = task_plan.grading_template

    grading_template.task_plan_type = ([ 'reading', 'homework' ] - [ task_plan.type ]).sample
    expect(task_plan).not_to be_valid

    grading_template.task_plan_type = task_plan.type
    expect(task_plan).to be_valid
  end

  it 'requires all tasking_plan due_ats to be in the future when publishing' do
    task_plan.is_publish_requested = true
    task_plan.settings['page_ids'] = [ page.id.to_s ];
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
    clone = FactoryBot.build :tasks_task_plan, cloned_from: task_plan
    clone.ecosystem = nil

    # Need to run UpdateTaskPlanEcosystem to be valid
    expect(clone).not_to be_valid
    expect(clone.ecosystem).to eq task_plan.ecosystem
  end

  it "automatically sets its ecosystem to the course's if cloned_from is not specified" do
    course = task_plan.course
    ecosystem = FactoryBot.create :content_ecosystem
    AddEcosystemToCourse[ecosystem: ecosystem, course: course]
    new_task_plan = FactoryBot.build :tasks_task_plan, course: course
    new_task_plan.ecosystem = nil
    expect(new_task_plan).to be_valid
    expect(new_task_plan.ecosystem).to eq ecosystem
  end

  it 'automatically sets wrq_count when validating' do
    wrq_1 = FactoryBot.create :content_exercise, page: page, question_answer_ids: [ [] ]
    wrq_2 = FactoryBot.create :content_exercise, page: page, question_answer_ids: [ [] ]

    task_plan = FactoryBot.create(
      :tasks_task_plan,
      type: 'homework',
      ecosystem: ecosystem.reload,
      settings: { 'page_ids' => [ page.id.to_s ], 'exercises' => [] }
    )
    expect(task_plan).to be_valid
    expect(task_plan.wrq_count).to eq 0

    [ wrq_1, wrq_2 ].each do |wrq|
      task_plan.settings['exercises'] << { 'id' => wrq.id.to_s, 'points' => [ 2.0 ] }
    end
    expect(task_plan).to be_valid
    expect(task_plan.wrq_count).to eq 2
  end

  context 'with tasks assigned to students' do
    let(:period) { FactoryBot.create :course_membership_period, course: task_plan.course }
    let(:teacher_student_role) do
      FactoryBot.create(:course_membership_teacher_student, period: period).role
    end
    let(:teacher_student_task) do
      FactoryBot.create :tasks_task, task_plan: task_plan, tasked_to: [ teacher_student_role ]
    end

    let(:student)      { FactoryBot.create(:course_membership_student, period: period) }
    let(:student_role) { student.role }
    let(:student_task) do
      FactoryBot.create :tasks_task, task_plan: task_plan, tasked_to: [ student_role ]
    end

    it 'knows if tasks are available to students' do
      expect(task_plan.out_to_students?).to eq false

      teacher_student_task
      expect(task_plan.reload.out_to_students?).to eq false

      student_task
      expect(task_plan.reload.out_to_students?).to eq true

      future_time = Time.current + 1.week
      student_task.update_attribute :opens_at_ntz, future_time
      expect(task_plan.reload.out_to_students?).to eq false
      expect(task_plan.reload.out_to_students?(current_time: future_time + 2.days)).to eq true
    end

    it 'allows name, description and due_at to be updated after a task is open' do
      student_task

      task_plan.title = 'New Title'
      task_plan.description = 'New description!'
      task_plan.tasking_plans.first.due_at = Time.current + 1.week
      expect(task_plan).to be_valid
      expect(task_plan.save).to eq true
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
      task_plan.reload.settings = { exercises: [] }
      expect(task_plan).to be_valid

      student_task

      task_plan.reload.settings = { exercises: [] }
      expect(task_plan).not_to be_valid
    end

    it 'aggregates wrq step counts from undropped unarchived student tasks only' do
      tasking_plan = task_plan.reload.tasking_plans.first
      tasking_plan.update_attribute :target, period
      student_task.gradable_step_count = 42
      student_task.ungraded_step_count = 21
      teacher_student_task.gradable_step_count = 84
      teacher_student_task.ungraded_step_count = 84
      [ student_task, teacher_student_task ].each do |task|
        task.opens_at = Time.current - 1.day
        task.due_at = Time.current - 1.day
        task.save validate: false
      end

      task_plan.update_gradable_step_counts!
      expect(tasking_plan.reload.gradable_step_count).to eq 42
      expect(tasking_plan.ungraded_step_count).to eq 21
      expect(task_plan.gradable_step_count).to eq 42
      expect(task_plan.ungraded_step_count).to eq 21

      period.destroy!
      task_plan.reload.update_gradable_step_counts!
      expect(tasking_plan.reload.gradable_step_count).to eq 42
      expect(tasking_plan.ungraded_step_count).to eq 21
      expect(task_plan.gradable_step_count).to eq 0
      expect(task_plan.ungraded_step_count).to eq 0

      period.restore!
      task_plan.reload.update_gradable_step_counts!
      expect(tasking_plan.reload.gradable_step_count).to eq 42
      expect(tasking_plan.ungraded_step_count).to eq 21
      expect(task_plan.gradable_step_count).to eq 42
      expect(task_plan.ungraded_step_count).to eq 21

      student.destroy!
      task_plan.update_gradable_step_counts!
      expect(tasking_plan.reload.gradable_step_count).to eq 0
      expect(tasking_plan.ungraded_step_count).to eq 0
      expect(task_plan.gradable_step_count).to eq 0
      expect(task_plan.ungraded_step_count).to eq 0
    end
  end
end

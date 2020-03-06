require 'rails_helper'

RSpec.describe Tasks::Models::Task, type: :model, speed: :medium do
  subject(:task) do
    FactoryBot.create :tasks_task, opens_at: Time.current - 1.week, due_at: Time.current - 1.day
  end

  it { is_expected.to belong_to(:task_plan).optional }

  it { is_expected.to belong_to(:time_zone).optional }

  it { is_expected.to have_many(:task_steps) }
  it { is_expected.to have_many(:taskings) }

  it { is_expected.to validate_presence_of(:title) }

  it 'is late when last_worked_at is past due_at' do
    expect(task).not_to be_late

    task.last_worked_at = Time.current
    task.save!

    expect(task).to be_late
  end

  it 'is always open if opens_at is nil' do
    task.update_attribute :opens_at, nil

    expect(task).to be_past_open
  end

  it 'is never due or late if due_at is nil' do
    task.update_attribute :due_at, nil

    expect(task).not_to be_past_due
    expect(task).not_to be_late

    task.last_worked_at = Time.current
    task.save!

    expect(task).not_to be_past_due
    expect(task).not_to be_late
  end

  context '#handle_task_step_completion!' do
    it 'sets #last_worked_at to completed_at' do
      time = Time.current

      task.handle_task_step_completion!(completed_at: time)

      expect(task.last_worked_at).to eq(time)
    end
  end

  it "requires non-nil due_at to be after opens_at" do
    expect(task).to be_valid

    task.due_at = Time.current - 1.week - 1.hour
    expect(task).to_not be_valid
  end

  it "reports is_shared? correctly" do
    FactoryBot.create(:tasks_tasking, task: task)
    expect(task.is_shared?).to eq false

    FactoryBot.create(:tasks_tasking, task: task)
    expect(task.is_shared?).to eq true
  end

  context 'with research cohort' do
      let!(:tasking) { FactoryBot.create(:tasks_tasking, task: task) }
      let(:student)  { tasking.role.student }
      let(:study)    { FactoryBot.create :research_study }
      let!(:cohort)  { FactoryBot.create :research_cohort, study: study }
      let!(:brain)   { FactoryBot.create :research_modified_tasked, study: study }
      before(:each)  {
        study.activate!
        Research::Models::CohortMember.create!(student: student, cohort: cohort)
      }

      it 'has links to related models' do
        expect(task.taskings).to eq [tasking]
        expect(task.roles).to eq [tasking.role]
        expect(student).to eq tasking.role.student
        expect(task.students).to eq [student]
        expect(task.research_cohorts).to eq [cohort]
        expect(task.research_study_brains).to eq [Research::Models::StudyBrain.find(brain.id)]
      end
  end

  context 'with task steps' do
    let(:core_step1) do
      FactoryBot.build(:tasks_tasked_reading, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :fixed_group
        step.is_core = true
      end
    end
    let(:core_step2) do
      FactoryBot.build(:tasks_tasked_reading, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :fixed_group
        step.is_core = true
      end
    end
    let(:core_step3) do
      FactoryBot.build(:tasks_tasked_reading, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :fixed_group
        step.is_core = true
      end
    end
    let(:personalized_step1) do
      FactoryBot.build(:tasks_tasked_exercise, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :personalized_group
        step.is_core = true
      end
    end
    let(:personalized_step2) do
      FactoryBot.build(:tasks_tasked_exercise, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :personalized_group
        step.is_core = true
      end
    end
    let(:spaced_practice_step1) do
      FactoryBot.build(:tasks_tasked_exercise, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :spaced_practice_group
        step.is_core = false
      end
    end
    let(:spaced_practice_step2) do
      FactoryBot.build(:tasks_tasked_exercise, skip_task: true).task_step.tap do |step|
        step.task = task
        step.group_type = :spaced_practice_group
        step.is_core = false
      end
    end

    before do
      task.task_steps = [
        core_step1, core_step2, core_step3,
        personalized_step1, personalized_step2,
        spaced_practice_step1, spaced_practice_step2
      ]
      task.save!
    end

    it 'returns fixed task steps' do
      fixed_steps = task.fixed_task_steps

      expect(fixed_steps.size).to eq(3)
      [core_step1, core_step2, core_step3].each do |step|
        expect(fixed_steps).to include(step)
      end
    end

    it 'returns personalized task steps' do
      personalized_steps = task.personalized_task_steps

      expect(personalized_steps.size).to eq(2)
      [personalized_step1, personalized_step2].each do |step|
        expect(personalized_steps).to include(step)
      end
    end

    it 'returns spaced_practice task steps' do
      spaced_practice_steps = task.spaced_practice_task_steps

      expect(spaced_practice_steps.size).to eq(2)
      [spaced_practice_step1, spaced_practice_step2].each do |step|
        expect(spaced_practice_steps).to include(step)
      end
    end

    it 'returns core task steps' do
      core_steps = task.core_task_steps

      expect(core_steps.size).to eq(5)
      [core_step1, core_step2, core_step3, personalized_step1, personalized_step2].each do |step|
        expect(core_steps).to include(step)
      end
    end

    it 'returns dynamic task steps' do
      dynamic_steps = task.dynamic_task_steps

      expect(dynamic_steps.size).to eq(2)
      [spaced_practice_step1, spaced_practice_step2].each do |step|
        expect(dynamic_steps).to include(step)
      end
    end

    it 'determines if its core task steps are completed' do
      expect(task.core_task_steps_completed?).to eq false

      task.core_task_steps.each do |task_step|
        allow(task_step).to receive(:completed?).and_return(true)
      end

      expect(task.core_task_steps_completed?).to eq true
    end
  end

  it 'knows when feedback should be available' do
    task.due_at = nil
    task.feedback_at = nil
    expect(task.feedback_available?).to eq true

    task.feedback_at = Time.current.yesterday
    expect(task.feedback_available?).to eq true

    task.feedback_at = Time.current.tomorrow
    expect(task.feedback_available?).to eq false
  end

  it 'counts exercise steps' do
    task = FactoryBot.create(
      :tasks_task, task_type: :homework, step_types: [ :tasks_tasked_exercise,
                                                       :tasks_tasked_reading,
                                                       :tasks_tasked_exercise,
                                                       :tasks_tasked_exercise ]
    )

    Preview::AnswerExercise[task_step: task.task_steps[0], is_correct: true]
    Preview::AnswerExercise[task_step: task.task_steps[3], is_correct: false]

    task.reload

    expect(task.exercise_count).to eq 3
    expect(task.completed_exercise_count).to eq 2
    expect(task.correct_exercise_count).to eq 1
  end

  context "update step counts" do
    let(:core_step_1) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap { |step| step.is_core = true }
    end
    let(:core_step_2) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap { |step| step.is_core = true }
    end

    let(:completed_core_step_1) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap do |step|
        step.is_core = true
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end
    let(:completed_core_step_2) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap do |step|
        step.is_core = true
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end

    let(:dynamic_step_1) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap { |step| step.is_core = false }
    end
    let(:dynamic_step_2) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap { |step| step.is_core = false }
    end

    let(:completed_dynamic_step_1) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap do |step|
        step.is_core = false
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end
    let(:completed_dynamic_step_2) do
      FactoryBot.build(:tasks_tasked_reading).task_step.tap do |step|
        step.is_core = false
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end

    let(:exercise_step_1) do
      FactoryBot.build(:tasks_tasked_exercise).task_step
    end
    let(:exercise_step_2) do
      FactoryBot.build(:tasks_tasked_exercise).task_step
    end

    let(:completed_exercise_step_1) do
      FactoryBot.build(:tasks_tasked_exercise).tap do |te|
        te.set_correct_answer_id
        te.make_incorrect!
      end.task_step.tap do |step|
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end
    let(:completed_exercise_step_2) do
      FactoryBot.build(:tasks_tasked_exercise).tap do |te|
        te.set_correct_answer_id
        te.make_incorrect!
      end.task_step.tap do |step|
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end

    let(:correct_exercise_step_1) do
      FactoryBot.build(:tasks_tasked_exercise).tap do |te|
        te.set_correct_answer_id
        te.make_correct!
      end.task_step.tap do |step|
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end
    let(:correct_exercise_step_2) do
      FactoryBot.build(:tasks_tasked_exercise).tap do |te|
        te.set_correct_answer_id
        te.make_correct!
      end.task_step.tap do |step|
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end

    let(:core_placeholder_step) do
      FactoryBot.build(:tasks_tasked_placeholder).tap do |tp|
        tp.placeholder_type = :unknown_type
      end.task_step.tap { |step| step.is_core = true }
    end
    let(:core_placeholder_exercise_step) do
      FactoryBot.build(:tasks_tasked_placeholder).tap do |tp|
        tp.placeholder_type = :exercise_type
      end.task_step.tap { |step| step.is_core = true }
    end

    let(:dynamic_placeholder_step) do
      FactoryBot.build(:tasks_tasked_placeholder).tap do |tp|
        tp.placeholder_type = :unknown_type
      end.task_step.tap { |step| step.is_core = false }
    end
    let(:dynamic_placeholder_exercise_step) do
      FactoryBot.build(:tasks_tasked_placeholder).tap do |tp|
        tp.placeholder_type = :exercise_type
      end.task_step.tap { |step| step.is_core = false }
    end

    context "core_page_ids" do
      it "works with no steps" do
        expect(task.core_page_ids).to eq []
      end

      it "works with multiple steps" do
        task.task_steps = [ completed_core_step_1, core_step_1, completed_dynamic_step_1 ]
        task.save!
        task.reload

        expect(task.core_page_ids).to(
          eq [ completed_core_step_1, core_step_1 ].map(&:content_page_id)
        )
      end
    end

    context "steps count" do
      context "total" do
        it "works with no steps" do
          expect(task.steps_count).to eq(0)
        end

        it "works with multiple steps" do
          task.task_steps = [core_step_1, dynamic_step_1]
          task.save!
          task.reload

          expect(task.steps_count).to eq(2)
        end
      end

      context "completed steps count" do
        it "works with no steps" do
          expect(task.completed_steps_count).to eq(0)
        end

        it "works with multiple completed steps" do
          task.task_steps = [completed_core_step_1, core_step_1, completed_dynamic_step_1]
          task.save!
          task.reload

          expect(task.completed_steps_count).to eq(2)
        end
      end

      context "core steps count" do
        it "works with no steps" do
          expect(task.core_steps_count).to eq(0)
        end

        it "works with multiple core steps" do
          task.task_steps = [core_step_1, dynamic_step_1, core_step_2]
          task.save!
          task.reload

          expect(task.core_steps_count).to eq(2)
        end
      end

      context "completed core steps count" do
        it "works with no steps" do
          expect(task.completed_core_steps_count).to eq(0)
        end

        it "works with multiple completed core steps" do
          task.task_steps = [
            completed_core_step_1,
            dynamic_step_1,
            core_step_1,
            completed_core_step_2
          ]
          task.save!
          task.reload

          expect(task.completed_core_steps_count).to eq(2)
        end
      end

      context "exercise steps count" do
        it "works with no steps" do
          expect(task.exercise_steps_count).to eq(0)
        end

        it "works with multiple exercise steps" do
          task.task_steps = [exercise_step_1, core_step_1, exercise_step_2]
          task.save!
          task.reload

          expect(task.exercise_steps_count).to eq(2)
        end
      end

      context "completed exercise steps count" do
        it "works with no steps" do
          expect(task.completed_exercise_steps_count).to eq(0)
        end

        it "works with multiple completed exercise steps" do
          task.task_steps = [
            completed_exercise_step_1, exercise_step_1, dynamic_step_1, completed_exercise_step_2
          ]
          task.save!
          task.reload

          expect(task.completed_exercise_steps_count).to eq(2)
        end
      end

      context "correct exercise steps count" do
        it "works with no steps" do
          expect(task.correct_exercise_steps_count).to eq(0)
        end

        it "works with multiple correct exercise steps" do
          task.task_steps = [
            correct_exercise_step_1, completed_exercise_step_1, correct_exercise_step_2
          ]
          task.save!
          task.reload

          expect(task.correct_exercise_steps_count).to eq(2)
        end
      end

      context "placeholder steps count" do
        it "works with no steps" do
          expect(task.placeholder_steps_count).to eq(0)
        end

        it "works with multiple placeholder steps" do
          task.task_steps = [core_placeholder_step, core_step_1, dynamic_placeholder_exercise_step]
          task.save!
          task.reload

          expect(task.placeholder_steps_count).to eq(2)
        end
      end

      context "placeholder exercise steps count" do
        it "works with no steps" do
          expect(task.placeholder_exercise_steps_count).to eq(0)
        end

        it "works with multiple placeholder exercise steps" do
          task.task_steps = [
            core_placeholder_exercise_step, core_placeholder_step, dynamic_placeholder_exercise_step
          ]
          task.save!
          task.reload

          expect(task.placeholder_exercise_steps_count).to eq(2)
        end
      end

      context "core placeholder exercise steps count" do
        it "works with no steps" do
          expect(task.core_placeholder_exercise_steps_count).to eq(0)
        end

        it "works with multiple placeholder exercise steps" do
          task.task_steps = [
            dynamic_placeholder_step,
            core_placeholder_exercise_step,
            dynamic_placeholder_exercise_step
          ]
          task.save!
          task.reload

          expect(task.core_placeholder_exercise_steps_count).to eq(1)
        end
      end

      it "updates on_time counts when the due date changes" do
        task = FactoryBot.create(
          :tasks_task, opens_at: Time.current - 1.week,
                       due_at: Time.current - 1.day,
                       step_types: [ :tasks_tasked_exercise ]
        )

        Preview::AnswerExercise[task_step: task.task_steps.first, is_correct: true]
        task.reload

        expect(task.completed_on_time_steps_count).to eq 0
        expect(task.completed_on_time_exercise_steps_count).to eq 0
        expect(task.correct_on_time_exercise_steps_count).to eq 0

        task.update_attributes(due_at: 1.day.from_now)
        task.reload

        expect(task.completed_on_time_steps_count).to eq 1
        expect(task.completed_on_time_exercise_steps_count).to eq 1
        expect(task.correct_on_time_exercise_steps_count).to eq 1
      end

      it "updates counts after any change to the task" do
        tasked_to = [ FactoryBot.create(:entity_role) ]
        task = FactoryBot.create :tasks_task, tasked_to: tasked_to, step_types: [
          :tasks_tasked_exercise,
          :tasks_tasked_exercise,
          :tasks_tasked_exercise,
          :tasks_tasked_exercise,
          :tasks_tasked_placeholder
        ]
        exercise_ids = [task.tasked_exercises.first.content_exercise_id]
        task.task_plan.update_attribute :settings, { 'exercise_ids' => exercise_ids }
        task.task_steps.first(4).each { |ts| ts.update_attribute :is_core, true }
        task.task_steps.last.update_attribute :is_core, false

        expect(task.completed_steps_count).to eq 0
        expect(task.completed_exercise_steps_count).to eq 0
        expect(task.correct_exercise_steps_count).to eq 0

        Preview::AnswerExercise[task_step: task.task_steps[0], is_correct: true, is_completed: true]
        task.reload

        expect(task.steps_count).to eq 5
        expect(task.exercise_steps_count).to eq 4
        expect(task.placeholder_steps_count).to eq 1

        expect(task.completed_steps_count).to eq 1
        expect(task.completed_exercise_steps_count).to eq 1
        expect(task.correct_exercise_steps_count).to eq 1

        Preview::AnswerExercise[
          task_step: task.task_steps[1], is_correct: false, is_completed: true
        ]
        task.reload

        expect(task.completed_steps_count).to eq 2
        expect(task.completed_exercise_steps_count).to eq 2
        expect(task.correct_exercise_steps_count).to eq 1

        Preview::AnswerExercise[
          task_step: task.task_steps[2], is_correct: true, is_completed: false
        ]
        task.reload

        expect(task.completed_steps_count).to eq 2
        expect(task.completed_exercise_steps_count).to eq 2
        expect(task.correct_exercise_steps_count).to eq 2

        Preview::AnswerExercise[
          task_step: task.task_steps[3], is_correct: false, is_completed: false
        ]
        task.reload

        expect(task.completed_steps_count).to eq 2
        expect(task.completed_exercise_steps_count).to eq 2
        expect(task.correct_exercise_steps_count).to eq 2

        MarkTaskStepCompleted[task_step: task.task_steps[2]]
        task.reload

        expect(task.completed_steps_count).to eq 3
        expect(task.completed_exercise_steps_count).to eq 3
        expect(task.correct_exercise_steps_count).to eq 2

        # The placeholder step is removed due to no available personalized exercises
        expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return(
          { accepted: true, exercises: [], spy_info: {} }
        ).once

        MarkTaskStepCompleted[task_step: task.task_steps[3]]
        task.reload

        expect(task.steps_count).to eq 4
        expect(task.exercise_steps_count).to eq 4
        expect(task.placeholder_steps_count).to eq 0

        expect(task.completed_steps_count).to eq 4
        expect(task.completed_exercise_steps_count).to eq 4
        expect(task.correct_exercise_steps_count).to eq 2

        second_exercise = task.task_steps.second.tasked
        second_exercise.update_attribute :answer_id, second_exercise.correct_answer_id
        task.reload

        expect(task.completed_steps_count).to eq 4
        expect(task.completed_exercise_steps_count).to eq 4
        expect(task.correct_exercise_steps_count).to eq 3
      end
    end

    it 'is hidden only if it has been hidden after being deleted for the last time' do
      expect(task).not_to be_hidden

      task.task_plan.destroy!
      expect(task.reload).not_to be_hidden

      task.hide.save!
      expect(task).to be_hidden

      task.task_plan.reload.restore!(recursive: true)
      expect(task.reload).not_to be_hidden

      task.task_plan.destroy!
      expect(task.reload).not_to be_hidden

      task.hide.save!
      expect(task).to be_hidden
    end

    it 'holds on to accepted late stats regardless of future work' do
      task = FactoryBot.create(:tasks_task, opens_at: Time.current - 1.week,
                                             due_at: Time.current,
                                             step_types: [:tasks_tasked_exercise,
                                                          :tasks_tasked_exercise,
                                                          :tasks_tasked_exercise])

      Timecop.freeze(Time.current - 1.day) do
        Preview::AnswerExercise[task_step: task.task_steps[0], is_correct: true]
        task.reload
      end

      expect(task.correct_exercise_count).to eq 1
      expect(task.completed_exercise_count).to eq 1
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.completed_accepted_late_exercise_count).to eq 0
      expect(task.correct_accepted_late_exercise_count).to eq 0
      expect(task.score).to eq 1/3.0

      Timecop.freeze(Time.current + 1.day) do
        Preview::AnswerExercise[task_step: task.task_steps[1], is_correct: true]
        task.reload
      end

      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.completed_accepted_late_exercise_count).to eq 0
      expect(task.correct_accepted_late_exercise_count).to eq 0
      expect(task.score).to eq 1/3.0

      task.accept_late_work
      task.save!

      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.completed_accepted_late_exercise_count).to eq 2
      expect(task.correct_accepted_late_exercise_count).to eq 2
      expect(task.score).to eq 2/3.0
      expect(task.accepted_late_at).not_to be_nil

      Timecop.freeze(Time.current + 1.day) do
        Preview::AnswerExercise[task_step: task.task_steps[2], is_correct: true]
        task.reload
      end

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.completed_accepted_late_exercise_count).to eq 2
      expect(task.correct_accepted_late_exercise_count).to eq 2
      expect(task.score).to eq 2/3.0

      task.accept_late_work
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.completed_accepted_late_exercise_count).to eq 3
      expect(task.correct_accepted_late_exercise_count).to eq 3
      expect(task.score).to eq 1.0

      task.reject_late_work
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.correct_accepted_late_exercise_count).to eq 0
      expect(task.completed_accepted_late_exercise_count).to eq 0
      expect(task.score).to eq 1/3.0
      expect(task.accepted_late_at).to be_nil
    end

    it 'holds on to accepted late stats regardless of future work and due date changes' do
      task = FactoryBot.create(
        :tasks_task, opens_at: Time.current - 1.week,
                     due_at: Time.current,
                     step_types: [ :tasks_tasked_exercise,
                                   :tasks_tasked_exercise,
                                   :tasks_tasked_exercise ]
      )

      Timecop.freeze(Time.current - 1.day) do
        Preview::AnswerExercise[task_step: task.task_steps[0], is_correct: true]
        task.reload
      end

      expect(task.correct_exercise_count).to eq 1
      expect(task.completed_exercise_count).to eq 1
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.correct_accepted_late_exercise_count).to eq 0
      expect(task.completed_accepted_late_exercise_count).to eq 0
      expect(task.score).to eq 1/3.0

      Timecop.freeze(Time.current + 1.day) do
        Preview::AnswerExercise[task_step: task.task_steps[1], is_correct: true]
        task.reload
      end

      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.correct_accepted_late_exercise_count).to eq 0
      expect(task.completed_accepted_late_exercise_count).to eq 0
      expect(task.score).to eq 1/3.0

      task.accept_late_work
      task.save!

      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.correct_accepted_late_exercise_count).to eq 2
      expect(task.completed_accepted_late_exercise_count).to eq 2
      expect(task.score).to eq 2/3.0
      expect(task.accepted_late_at).not_to be_nil

      Timecop.freeze(Time.current + 1.day) do
        Preview::AnswerExercise[task_step: task.task_steps[2], is_correct: true]
        task.reload
      end

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.correct_accepted_late_exercise_count).to eq 2
      expect(task.completed_accepted_late_exercise_count).to eq 2
      expect(task.score).to eq 2/3.0

      task.accept_late_work
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.correct_accepted_late_exercise_count).to eq 3
      expect(task.completed_accepted_late_exercise_count).to eq 3
      expect(task.score).to eq 1.0

      task.due_at = Time.current + 2.days
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 3
      expect(task.correct_on_time_exercise_count).to eq 3
      expect(task.completed_accepted_late_exercise_count).to eq 3
      expect(task.correct_accepted_late_exercise_count).to eq 3
      expect(task.score).to eq 1.0

      task.due_at = Time.current
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.completed_accepted_late_exercise_count).to eq 3
      expect(task.correct_accepted_late_exercise_count).to eq 3
      expect(task.score).to eq 1.0

      task.reject_late_work
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completed_on_time_exercise_count).to eq 1
      expect(task.correct_on_time_exercise_count).to eq 1
      expect(task.correct_accepted_late_exercise_count).to eq 0
      expect(task.completed_accepted_late_exercise_count).to eq 0
      expect(task.score).to eq 1/3.0
      expect(task.accepted_late_at).to be_nil
    end

  end
end

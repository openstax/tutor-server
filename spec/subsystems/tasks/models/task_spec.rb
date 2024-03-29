require 'rails_helper'

RSpec.describe Tasks::Models::Task, type: :model, speed: :medium do
  subject(:task)         do
    FactoryBot.create(
      :tasks_task,
      opens_at: Time.current - 1.week,
      due_at: Time.current - 2.days,
      closes_at: Time.current - 1.day,
      num_random_taskings: 1
    )
  end

  let(:tasking)          { task.taskings.first }
  let(:role)             { tasking.role }
  let(:task_plan)        { task.task_plan }
  let(:grading_template) { task_plan.grading_template }

  it { is_expected.to belong_to(:task_plan).optional }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to have_many(:task_steps) }
  it { is_expected.to have_many(:taskings) }

  it { is_expected.to validate_presence_of(:title) }

  it 'can find its own extension' do
    extension = FactoryBot.create :tasks_extension, task_plan: task_plan, role: role

    expect(task.extension).to eq extension
  end

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

  it 'is never closed if closes_at is nil' do
    task.update_attribute :closes_at, nil

    expect(task).not_to be_past_close
  end

  context '#handle_task_step_completion!' do
    it 'sets #last_worked_at to completed_at' do
      time = Time.current

      task.handle_task_step_completion!(completed_at: time)

      expect(task.last_worked_at).to eq(time)
    end
  end

  context '#close_and_make_due!' do
    it 'sets closes_at and due_at' do
      time = Time.current

      task.close_and_make_due!(time: time)

      expect(task.due_at_ntz).to eq(time)
      expect(task.closes_at_ntz).to eq(time)
    end
  end

  it 'requires non-nil due_at to be after opens_at' do
    expect(task).to be_valid

    task.due_at = Time.current - 1.week - 1.hour
    expect(task).to_not be_valid
  end

  it 'requires non-nil closes_at to be after due_at' do
    expect(task).to be_valid

    task.closes_at = Time.current - 2.days - 1.hour
    expect(task).to_not be_valid
  end

  it 'reports is_shared? correctly' do
    expect(task.reload.is_shared?).to eq false

    FactoryBot.create(:tasks_tasking, task: task)
    expect(task.reload.is_shared?).to eq true
  end

  it 'defaults shuffle_answer_choices to true' do
    task.grading_template.shuffle_answer_choices = true
    expect(task.shuffle_answer_choices).to eq true

    task.grading_template.shuffle_answer_choices = false
    expect(task.shuffle_answer_choices).to eq false

    task_plan.grading_template = nil
    expect(task.shuffle_answer_choices).to eq true
  end

  context 'with research cohort' do
    let(:student)  { role.student }
    let(:study)    { FactoryBot.create :research_study }
    let!(:cohort)  { FactoryBot.create :research_cohort, study: study }
    before(:each)  {
      study.activate!
      Research::Models::CohortMember.create!(student: student, cohort: cohort)
    }

    it 'has links to related models' do
      expect(task.taskings).to eq [tasking]
      expect(task.roles).to eq [role]
      expect(task.students).to eq [student]
      expect(task.research_cohorts).to eq [cohort]
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

  it 'reads completion_weight from the grading_template with fallbacks if absent' do
    expect(task.completion_weight).to eq grading_template.completion_weight

    task_plan.grading_template = nil
    expect(task.completion_weight).to eq task.reading? ? 0.9 : 0
  end

  it 'reads correctness_weight from the grading_template with fallbacks if absent' do
    expect(task.correctness_weight).to eq grading_template.correctness_weight

    task_plan.grading_template = nil
    expect(task.correctness_weight).to eq task.reading? ? 0.1 : 1
  end

  it 'reads auto_grading_feedback_on from the grading_template with fallbacks if absent' do
    expect(task.auto_grading_feedback_on).to eq grading_template.auto_grading_feedback_on

    task_plan.grading_template = nil
    expect(task.auto_grading_feedback_on).to eq 'answer'
  end

  it 'knows when auto grading feedback should be available' do
    task.due_at = nil
    grading_template.auto_grading_feedback_on = :answer
    expect(task.auto_grading_feedback_available?).to eq true

    grading_template.auto_grading_feedback_on = :due
    expect(task.auto_grading_feedback_available?).to eq false

    task.due_at = task.time_zone.now
    expect(task.auto_grading_feedback_available?).to eq true

    grading_template.auto_grading_feedback_on = :publish
    expect(task.auto_grading_feedback_available?).to eq false
  end

  it 'knows when manual grading feedback should be available' do
    grading_template.manual_grading_feedback_on = :grade
    expect(task.manual_grading_feedback_available?).to eq false

    grading_template.manual_grading_feedback_on = :publish
    expect(task.manual_grading_feedback_available?).to eq false
  end

  it 'reads manual_grading_feedback_on from the grading_template with fallbacks if absent' do
    expect(task.manual_grading_feedback_on).to eq grading_template.manual_grading_feedback_on

    task_plan.grading_template = nil
    expect(task.manual_grading_feedback_on).to eq 'grade'
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

  context 'update step counts' do
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

    let(:gradable_step) do
      FactoryBot.build(:tasks_tasked_exercise, answer_ids: []).tap do |te|
        te.update_attribute :free_response, 'Hello there!'
      end.task_step.tap do |step|
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end

    let(:graded_step) do
      FactoryBot.build(:tasks_tasked_exercise, answer_ids: []).tap do |te|
        te.update_attribute :free_response, "What's up?"

        te.grader_points = 1.0
        te.last_graded_at = Time.current
        te.save!
      end.task_step.tap do |step|
        step.first_completed_at = Time.current
        step.last_completed_at = Time.current
      end
    end

    context 'core_page_ids' do
      it 'works with no steps' do
        expect(task.core_page_ids).to eq []
      end

      it 'works with multiple steps' do
        task.task_steps = [ completed_core_step_1, core_step_1, completed_dynamic_step_1 ]
        task.save!
        task.reload

        expect(task.core_page_ids).to(
          eq [ completed_core_step_1, core_step_1 ].map(&:content_page_id)
        )
      end
    end

    context 'steps count' do
      context 'total' do
        it 'works with no steps' do
          expect(task.steps_count).to eq(0)
        end

        it 'works with multiple steps' do
          task.task_steps = [core_step_1, dynamic_step_1]
          task.save!
          task.reload

          expect(task.steps_count).to eq(2)
        end
      end

      context 'completed steps count' do
        it 'works with no steps' do
          expect(task.completed_steps_count).to eq(0)
        end

        it 'works with multiple completed steps' do
          task.task_steps = [completed_core_step_1, core_step_1, completed_dynamic_step_1]
          task.save!
          task.reload

          expect(task.completed_steps_count).to eq(2)
        end
      end

      context 'core steps count' do
        it 'works with no steps' do
          expect(task.core_steps_count).to eq(0)
        end

        it 'works with multiple core steps' do
          task.task_steps = [core_step_1, dynamic_step_1, core_step_2]
          task.save!
          task.reload

          expect(task.core_steps_count).to eq(2)
        end
      end

      context 'completed core steps count' do
        it 'works with no steps' do
          expect(task.completed_core_steps_count).to eq(0)
        end

        it 'works with multiple completed core steps' do
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

      context 'exercise steps count' do
        it 'works with no steps' do
          expect(task.exercise_steps_count).to eq(0)
        end

        it 'works with multiple exercise steps' do
          task.task_steps = [exercise_step_1, core_step_1, exercise_step_2]
          task.save!
          task.reload

          expect(task.exercise_steps_count).to eq(2)
        end
      end

      context 'completed exercise steps count' do
        it 'works with no steps' do
          expect(task.completed_exercise_steps_count).to eq(0)
        end

        it 'works with multiple completed exercise steps' do
          task.task_steps = [
            completed_exercise_step_1, exercise_step_1, dynamic_step_1, completed_exercise_step_2
          ]
          task.save!
          task.reload

          expect(task.completed_exercise_steps_count).to eq(2)
        end
      end

      context 'correct exercise steps count' do
        it 'works with no steps' do
          expect(task.correct_exercise_steps_count).to eq(0)
        end

        it 'works with multiple correct exercise steps' do
          task.task_steps = [
            correct_exercise_step_1, completed_exercise_step_1, correct_exercise_step_2
          ]
          task.save!
          task.reload

          expect(task.correct_exercise_steps_count).to eq(2)
        end
      end

      context 'placeholder steps count' do
        it 'works with no steps' do
          expect(task.placeholder_steps_count).to eq(0)
        end

        it 'works with multiple placeholder steps' do
          task.task_steps = [core_placeholder_step, core_step_1, dynamic_placeholder_exercise_step]
          task.save!
          task.reload

          expect(task.placeholder_steps_count).to eq(2)
        end
      end

      context 'placeholder exercise steps count' do
        it 'works with no steps' do
          expect(task.placeholder_exercise_steps_count).to eq(0)
        end

        it 'works with multiple placeholder exercise steps' do
          task.task_steps = [
            core_placeholder_exercise_step, core_placeholder_step, dynamic_placeholder_exercise_step
          ]
          task.save!
          task.reload

          expect(task.placeholder_exercise_steps_count).to eq(2)
        end
      end

      context 'core placeholder exercise steps count' do
        it 'works with no steps' do
          expect(task.core_placeholder_exercise_steps_count).to eq(0)
        end

        it 'works with multiple placeholder exercise steps' do
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

      context 'gradable step count' do
        it 'works with no steps' do
          expect(task.gradable_step_count).to eq(0)
        end

        it 'works with multiple completed exercise steps' do
          task.task_steps = [
            completed_exercise_step_1,
            exercise_step_1,
            dynamic_step_1,
            completed_exercise_step_2,
            gradable_step,
            graded_step
          ]
          task.save!
          task.reload

          expect(task.gradable_step_count).to eq(2)
        end
      end

      context 'ungraded step count' do
        it 'works with no steps' do
          expect(task.ungraded_step_count).to eq(0)
        end

        it 'works with multiple completed exercise steps' do
          task.task_steps = [
            completed_exercise_step_1,
            exercise_step_1,
            dynamic_step_1,
            completed_exercise_step_2,
            gradable_step,
            graded_step
          ]
          task.save!
          task.reload

          expect(task.ungraded_step_count).to eq(1)
        end
      end

      it 'updates counts after any change to the task' do
        tasked_to = [ FactoryBot.create(:entity_role) ]
        task = FactoryBot.create :tasks_task, tasked_to: tasked_to, step_types: [
          :tasks_tasked_exercise,
          :tasks_tasked_exercise,
          :tasks_tasked_exercise,
          :tasks_tasked_exercise,
          :tasks_tasked_placeholder
        ]
        exercise = task.tasked_exercises.first.exercise
        exercises = [
          { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
        ]
        task.task_plan.update_attribute :settings, exercises: exercises
        task.task_steps.first(4).each { |ts| ts.update_attribute :is_core, true }
        task.task_steps.last.update_attribute :is_core, false

        expect(task.completed_steps_count).to eq 0
        expect(task.completed_exercise_steps_count).to eq 0
        expect(task.correct_exercise_steps_count).to eq 0

        Preview::AnswerExercise[
          task_step: task.task_steps[0], is_correct: true, is_completed: true
        ]
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
        expect_any_instance_of(Tasks::FetchAssignmentPes).to receive(:call).and_return(
          Lev::Routine::Result.new(Lev::Outputs.new(exercises: []), Lev::Errors.new)
        )

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
  end

  it 'is hidden only if it has been hidden after being deleted for the last time' do
    expect(task).not_to be_hidden

    task_plan.destroy!
    expect(task.reload).not_to be_hidden

    task.hide.save!
    expect(task).to be_hidden

    task_plan.reload.restore!(recursive: true)
    expect(task.reload).not_to be_hidden

    task_plan.destroy!
    expect(task.reload).not_to be_hidden

    task.hide.save!
    expect(task).to be_hidden
  end

  it 'calculates points and scores with and without lateness penalties' do
    task = FactoryBot.create(
      :tasks_task, step_types: [
        :tasks_tasked_exercise, :tasks_tasked_exercise, :tasks_tasked_exercise
      ]
    )
    task.taskings << FactoryBot.build(:tasks_tasking)
    task.grading_template.update_columns(
      late_work_penalty_applied: :immediately,
      late_work_penalty: 0.5
    )

    due_at = task.due_at

    Timecop.freeze(due_at - 1.day) do
      Preview::AnswerExercise[task_step: task.task_steps.first, is_correct: true]
      task.reload

      expect(task.correct_exercise_count).to eq 1
      expect(task.completed_exercise_count).to eq 1
      expect(task.completion).to eq 1/3.0
      expect(task.points_without_lateness).to eq 1.0
      expect(task.points).to eq 1.0
      expect(task.score_without_lateness).to eq 1/3.0
      expect(task.score).to eq 1/3.0
    end

    Timecop.freeze(due_at + 1.hour) do
      Preview::AnswerExercise[task_step: task.task_steps.second, is_correct: true]
      task.reload

      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completion).to eq 2/3.0
      expect(task.points_without_lateness).to eq 2.0
      expect(task.points).to eq 1.5
      expect(task.score_without_lateness).to eq 2/3.0
      expect(task.score).to eq 0.5

      extension = Tasks::Models::Extension.new(
        entity_role_id: task.taskings.first.entity_role_id,
        due_at: task.time_zone.now + 1.minute,
        closes_at: task.time_zone.now + 1.minute
      )
      task.task_plan.extensions << extension
      expect(task.reload.extension).to eq extension

      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completion).to eq 2/3.0
      expect(task.points_without_lateness).to eq 2.0
      expect(task.points).to eq 2.0
      expect(task.score_without_lateness).to eq 2/3.0
      expect(task.score).to eq 2/3.0
    end

    Timecop.freeze(due_at + 25.hours) do
      expect(task.correct_exercise_count).to eq 2
      expect(task.completed_exercise_count).to eq 2
      expect(task.completion).to eq 2/3.0
      expect(task.points_without_lateness).to eq 2.0
      expect(task.points).to eq 2.0
      expect(task.score_without_lateness).to eq 2/3.0
      expect(task.score).to eq 2/3.0

      Preview::AnswerExercise[task_step: task.task_steps.third, is_correct: true]
      task.reload

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completion).to eq 1.0
      expect(task.points_without_lateness).to eq 3.0
      expect(task.points).to eq 2.5
      expect(task.score_without_lateness).to eq 1.0
      expect(task.score).to eq 2.5/3.0

      task.grading_template.update_columns(
        late_work_penalty_applied: :daily,
        late_work_penalty: 0.3
      )

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completion).to eq 1.0
      expect(task.points_without_lateness).to eq 3.0
      expect(task.points).to eq 2.7
      expect(task.score_without_lateness).to eq 1.0
      expect(task.score).to eq 0.9

      task.extension.due_at = task.time_zone.now
      task.extension.closes_at = task.time_zone.now
      task.extension.save!
      task.reload

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completion).to eq 1.0
      expect(task.points_without_lateness).to eq 3.0
      expect(task.points).to eq 3.0
      expect(task.score_without_lateness).to eq 1.0
      expect(task.score).to eq 1.0

      task.due_at = due_at + 3.days
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completion).to eq 1.0
      expect(task.points_without_lateness).to eq 3.0
      expect(task.points).to eq 3.0
      expect(task.score_without_lateness).to eq 1.0
      expect(task.score).to eq 1.0

      task.due_at = due_at
      task.save!

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completion).to eq 1.0
      expect(task.points_without_lateness).to eq 3.0
      expect(task.points).to eq 3.0
      expect(task.score_without_lateness).to eq 1.0
      expect(task.score).to eq 1.0

      task.extension.destroy!
      task.reload

      expect(task.correct_exercise_count).to eq 3
      expect(task.completed_exercise_count).to eq 3
      expect(task.completion).to eq 1.0
      expect(task.points_without_lateness).to eq 3.0
      expect(task.points).to eq 2.1
      expect(task.score_without_lateness).to eq 1.0
      expect(task.score).to be_within(1e-6).of(0.7)
    end
  end

  it 'caches scores before and after due date' do
    task.grading_template.update_column :auto_grading_feedback_on, :due
    task.due_at = Time.current + 1.hour
    task.closes_at = Time.current + 2.hours
    task.save!

    expect(task.available_points).to eq 0.0
    expect(task.published_points_before_due).to be_nan
    expect(task.published_points_after_due).to be_nan
    expect(task.published_points).to be_nil
    expect(task.is_provisional_score_before_due).to eq false
    expect(task.is_provisional_score_after_due).to eq false
    expect(task.provisional_score?).to eq false

    task_step = FactoryBot.build(:tasks_tasked_exercise, skip_task: true).task_step
    task_step.task = task
    task_step.save!
    Preview::AnswerExercise.call task_step: task_step, is_correct: true

    expect(task.reload.available_points).to eq 1.0
    expect(task.published_points_before_due).to be_nan
    expect(task.published_points_after_due).to eq 1.0
    expect(task.published_points).to be_nil
    expect(task.is_provisional_score_before_due).to eq false
    expect(task.is_provisional_score_after_due).to eq false
    expect(task.provisional_score?).to eq false
  end

  it 'uses teacher-chosen points for homework assignments' do
    course = task_plan.course
    period = task_plan.tasking_plans.first.target
    FactoryBot.create :course_membership_student, period: period

    simple_exercise = FactoryBot.create :content_exercise
    page = simple_exercise.page
    multipart_exercise = FactoryBot.create :content_exercise, page: page, num_questions: 3

    ecosystem = page.ecosystem
    AddEcosystemToCourse.call ecosystem: ecosystem, course: course

    task_plan.grading_template.update_column :task_plan_type, 'homework'
    task_plan.update_attributes!(
      ecosystem: ecosystem,
      type: 'homework',
      assistant: FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
      ),
      settings: {
        page_ids: [ page.id.to_s ],
        exercises: [
          { id: simple_exercise.id.to_s, points: [ 1.0 ] },
          { id: multipart_exercise.id.to_s, points: [ 2.0, 3.0, 4.0 ] }
        ],
        exercises_count_dynamic: 0
      }
    )
    task_plan.tasks.delete_all
    DistributeTasks[task_plan: task_plan]

    task = task_plan.tasks.first
    expect(task.points).to be_nil

    Preview::AnswerExercise[task_step: task.task_steps.first, is_correct: true]
    expect(task.points).to eq 1.0

    Preview::AnswerExercise[task_step: task.task_steps.second, is_correct: true]
    expect(task.points).to eq 3.0

    Preview::AnswerExercise[task_step: task.task_steps.third, is_correct: true]
    expect(task.points).to eq 6.0

    Preview::AnswerExercise[task_step: task.task_steps.fourth, is_correct: true]
    expect(task.points).to eq 10.0
  end
end

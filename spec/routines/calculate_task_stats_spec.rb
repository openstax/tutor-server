require 'rails_helper'
require 'vcr_helper'

RSpec.describe CalculateTaskStats, type: :routine, speed: :slow, vcr: VCR_OPTS do

  before(:all) do
    @number_of_students = 8

    begin
      RSpec::Mocks.setup

      @task_plan = FactoryGirl.create :tasked_task_plan, number_of_students: @number_of_students
      @period = @task_plan.owner.periods.first
    ensure
      RSpec::Mocks.teardown
    end
  end

  # Workaround for PostgreSQL bug where the task records
  # stop existing in SELECT ... FOR UPDATE queries (but not in regular SELECTs)
  # after the transaction rollback that happens in-between spec examples
  before(:each) { @task_plan.tasks.each(&:touch) }

  let(:student_tasks) do
    @task_plan.tasks.joins(taskings: {role: :student}).to_a
  end

  context "with an unworked plan" do

    let(:stats) { described_class.call(tasks: @task_plan.tasks).outputs.stats }

    it "is all nil or zero for an unworked task_plan" do
      expect(stats.first.mean_grade_percent).to be_nil
      expect(stats.first.total_count).to eq(student_tasks.length)
      expect(stats.first.complete_count).to eq(0)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages[0]
      expect(page.student_count).to eq(0) # no students have worked yet
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)
      expect(page.trouble).to eq false

      expect(stats.first.spaced_pages).to be_empty
    end

    it 'does not break if an exercise has more than one tag' do
      cnx_page = OpenStax::Cnx::V1::Page.new(hash: {
        'id' => 'e26d1433-f8e4-41db-a757-0e061d6d2737',
        'title' => 'Prokaryotic Cells'
      })
      page = Content::Routines::ImportPage.call(
        cnx_page: cnx_page, chapter: FactoryGirl.create(:content_chapter),
        book_location: [1, 1]
      ).outputs.page

      Content::Routines::PopulateExercisePools[book: page.chapter.book]

      course = FactoryGirl.create :course_profile_course, :with_assistants
      AddEcosystemToCourse[course: course, ecosystem: page.ecosystem]

      period = FactoryGirl.create :course_membership_period, course: course
      student = FactoryGirl.create(:user)
      AddUserAsPeriodStudent.call(user: student, period: period)

      task_plan = FactoryGirl.create(
        :tasks_task_plan,
        owner: course,
        ecosystem: page.ecosystem,
        settings: { 'page_ids' => [page.id.to_s] },
        assistant: get_assistant(course: course, task_plan_type: 'reading')
      )

      DistributeTasks.call(task_plan: task_plan)

      expect(stats.first.complete_count).to eq 0
    end

  end

  context "after task steps are marked as completed" do

    it "records partial/complete status" do
      first_task = student_tasks.first
      step = first_task.task_steps.where(
        tasked_type: "Tasks::Models::TaskedReading"
      ).first
      MarkTaskStepCompleted[task_step: step]
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.mean_grade_percent).to be_nil
      expect(stats.first.complete_count).to eq(0)
      expect(stats.first.partially_complete_count).to eq(1)
      expect(stats.first.trouble).to eq false

      work_task(task: first_task, is_correct: false)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq true

      last_task = student_tasks.last
      MarkTaskStepCompleted[task_step: last_task.task_steps.first]
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(1)
      expect(stats.first.trouble).to eq true
    end

  end

  context "after task steps are marked as correct or incorrect" do

    it "records them" do
      work_task(task: student_tasks[0], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.mean_grade_percent).to eq (100)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(1) # num students with completed task steps
      expect(page['correct_count']).to eq(student_tasks[0].exercise_steps.size)
      expect(page['incorrect_count']).to eq(0)
      expect(page['trouble']).to eq false

      expect(stats.first.spaced_pages).to be_empty

      work_task(task: student_tasks[1], is_correct: false)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (50)
      expect(stats.first.complete_count).to eq(2)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(2)
      expect(page['correct_count']).to eq(student_tasks[0].exercise_steps.size)
      expect(page['incorrect_count']).to eq(student_tasks[1].exercise_steps.size)
      expect(page['chapter_section']).to eq([1, 1])
      expect(page['trouble']).to eq false

      expect(stats.first.spaced_pages).to be_empty

      work_task(task: student_tasks[2], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (67)
      expect(stats.first.complete_count).to eq(3)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(3)
      expect(page['correct_count']).to eq(
        student_tasks[0].exercise_steps.size +
        student_tasks[2].exercise_steps.size
      )
      expect(page['incorrect_count']).to eq(student_tasks[1].exercise_steps.size)
      expect(page['chapter_section']).to eq([1, 1])
      expect(page['trouble']).to eq false

      expect(stats.first.spaced_pages).to be_empty

      work_task(task: student_tasks[3], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (75)
      expect(stats.first.complete_count).to eq(4)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(4)
      expect(page['correct_count']).to eq(
        student_tasks[0].exercise_steps.size +
        student_tasks[2].exercise_steps.size +
        student_tasks[3].exercise_steps.size
      )
      expect(page['incorrect_count']).to eq(student_tasks[1].exercise_steps.size)
      expect(page['chapter_section']).to eq([1, 1])
      expect(page['trouble']).to eq false

      expect(stats.first.spaced_pages).to be_empty
    end

    # This test assumes that all of these tasks have the same numbers of steps,
    # which is true at least for now
    it "sets trouble to true if >50% incorrect and >25% completed" do
      stats = described_class.call(tasks: @task_plan.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      expect(stats.first.spaced_pages).to be_empty

      # Less than 25% done: no trouble
      work_task(task: student_tasks[0], is_correct: false, num_steps: 5)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      expect(stats.first.spaced_pages).to be_empty

      # Over 25% done: trouble
      work_task(task: student_tasks[1], is_correct: false)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      expect(stats.first.spaced_pages).to be_empty

      work_task(task: student_tasks[2], is_correct: false)

      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      expect(stats.first.spaced_pages).to be_empty

      # 40% correct: still trouble
      student_tasks[3..4].each { |task| work_task(task: task, is_correct: true) }
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      expect(stats.first.spaced_pages).to be_empty

      # 50% correct: no more trouble
      work_task(task: student_tasks[5], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      expect(stats.first.spaced_pages).to be_empty

      # 3 out of 7 correct: trouble again
      work_task(task: student_tasks[6], is_correct: false)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      expect(stats.first.spaced_pages).to be_empty

      # 50% correct: no more trouble
      work_task(task: student_tasks[7], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      expect(stats.first.spaced_pages).to be_empty
    end

    it "returns detailed stats if :details is true" do
      tasks = student_tasks[0..2]

      student_names_map = Hash.new { |hash, key| hash[key] = [] }
      free_responses_map = Hash.new do |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = [] }
      end
      selected_answers_map = Hash.new do |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = [] }
      end
      tasks.each_with_index do |task, ii|
        work_task task: task, is_correct: (ii.even? ? true : false)

        roles = task.taskings.map(&:role)
        users = Role::GetUsersForRoles[roles]
        student_names = users.map(&:name).sort.join('; ')

        task.exercise_steps.each do |exercise_step|
          tasked = exercise_step.tasked
          exercise = tasked.exercise
          question_ids = exercise.questions_hash.map { |question| question['id'].to_s }
          question_ids.each do |question_id|
            student_names_map[question_id] << student_names
            free_responses_map[question_id][student_names] << tasked.free_response
            selected_answers_map[question_id][student_names] << tasked.answer_id
          end
        end
      end

      stats = described_class.call(tasks: @task_plan.reload.tasks, details: true).outputs.stats

      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.content).to be_kind_of(String)
        expect(exercise.question_stats.length).to eq 1
        exercise.question_stats.each_with_index do |question_stats, qq|
          question_id = question_stats.question_id
          expect(question_id).to be_kind_of(String)
          expect(question_stats.answered_count).to be <= 3
          expect(question_stats.answers.length).to eq question_stats.answered_count
          student_names = question_stats.answers.flat_map(&:student_names)
          expect(student_names).to match_array student_names_map[question_id]
          question_stats.answers.group_by do |student_answer|
            student_answer.student_names.sort.join('; ')
          end.each do |student_names, student_answers|
            expect(student_answers.map(&:free_response)).to(
              match_array free_responses_map[question_id][student_names]
            )
            expect(student_answers.map(&:answer_id)).to(
              match_array selected_answers_map[question_id][student_names]
            )
          end

          question_answer_ids = answer_ids(exercise.content, qq)
          expected_answer_stats = question_answer_ids.map do |aid|
            {
              answer_id: aid,
              selected_count: selected_answers_map.values.map(&:values).flatten.count(aid)
            }
          end
          expect(question_stats.answer_stats).to match_array expected_answer_stats
        end
      end

    end
  end

  context "with multiple course periods" do
    let(:course)   { @task_plan.owner }
    let(:period_2) { FactoryGirl.create :course_membership_period, course: course }
    let(:stats)    { described_class.call(tasks: @task_plan.tasks).outputs.stats }

    before do
      student_tasks.last(@number_of_students/2).each do |task|
        task.taskings.each do |tasking|
          ::MoveStudent.call(period: period_2, student: tasking.role.student)
        end
      end
    end

    context "if the students were already in the periods before the assignment" do
      before do
        student_tasks.last(@number_of_students/2).each do |task|
          task.taskings.each do |tasking|
            tasking.period = period_2.to_model
            tasking.save!
          end
        end
      end

      it "splits the students into their periods" do
        expect(stats.first.mean_grade_percent).to be_nil
        expect(stats.first.total_count).to eq(student_tasks.length/2)
        expect(stats.first.complete_count).to eq(0)
        expect(stats.first.partially_complete_count).to eq(0)
        expect(stats.first.trouble).to eq false

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)
        expect(page.trouble).to eq false

        expect(stats.first.spaced_pages).to be_empty

        expect(stats.second.mean_grade_percent).to be_nil
        expect(stats.second.total_count).to eq(student_tasks.length/2)
        expect(stats.second.complete_count).to eq(0)
        expect(stats.second.partially_complete_count).to eq(0)
        expect(stats.second.trouble).to eq false

        page = stats.second.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)
        expect(page.trouble).to eq false

        expect(stats.second.spaced_pages).to be_empty
      end

      context 'if a period was archived after the assignment was distributed' do
        before { period_2.to_model.destroy }

        it 'does not show the archived period' do
          expect(stats.first.mean_grade_percent).to be_nil
          expect(stats.first.total_count).to eq(student_tasks.length/2)
          expect(stats.first.complete_count).to eq(0)
          expect(stats.first.partially_complete_count).to eq(0)
          expect(stats.first.trouble).to eq false

          page = stats.first.current_pages[0]
          expect(page.student_count).to eq(0)
          expect(page.incorrect_count).to eq(0)
          expect(page.correct_count).to eq(0)
          expect(page.trouble).to eq false

          expect(stats.first.spaced_pages).to be_empty

          expect(stats.second).to be_nil
        end
      end
    end

    context "if the students changed periods after the assignment was distributed" do
      it "shows students that changed periods in their original period" do
        expect(stats.first.mean_grade_percent).to be_nil
        expect(stats.first.total_count).to eq(student_tasks.length)
        expect(stats.first.complete_count).to eq(0)
        expect(stats.first.partially_complete_count).to eq(0)
        expect(stats.first.trouble).to eq false

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)
        expect(page.trouble).to eq false

        expect(stats.first.spaced_pages).to be_empty

        expect(stats.second).to be_nil
      end

      context 'if the old period was archived after the assignment was distributed' do
        before { @period.destroy }

        it "shows no stats" do
          expect(stats.first).to be_nil
        end
      end

      context 'if the new period was archived after the assignment was distributed' do
        before { period_2.to_model.destroy }

        it "shows students that changed periods in their original period" do
          expect(stats.first.mean_grade_percent).to be_nil
          expect(stats.first.total_count).to eq(student_tasks.length)
          expect(stats.first.complete_count).to eq(0)
          expect(stats.first.partially_complete_count).to eq(0)
          expect(stats.first.trouble).to eq false

          page = stats.first.current_pages[0]
          expect(page.student_count).to eq(0)
          expect(page.incorrect_count).to eq(0)
          expect(page.correct_count).to eq(0)
          expect(page.trouble).to eq false

          expect(stats.first.spaced_pages).to be_empty

          expect(stats.second).to be_nil
        end
      end
    end

    context "if the students were dropped after working the assignment" do
      it "does not show dropped students" do
        first_task = student_tasks.first
        work_task(task: first_task, is_correct: true)

        stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

        expect(stats.first.mean_grade_percent).to eq 100
        expect(stats.first.complete_count).to eq 1
        expect(stats.first.partially_complete_count).to eq 0
        expect(stats.first.trouble).to eq false

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq 1
        expect(page.incorrect_count).to eq 0
        expect(page.correct_count).to eq first_task.exercise_steps.size
        expect(page.trouble).to eq false

        expect(stats.first.spaced_pages).to be_empty

        first_task.taskings.first.role.student.destroy

        stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

        expect(stats.first.mean_grade_percent).to be_nil
        expect(stats.first.total_count).to eq student_tasks.length - 1
        expect(stats.first.complete_count).to eq 0
        expect(stats.first.partially_complete_count).to eq 0
        expect(stats.first.trouble).to eq false

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq 0
        expect(page.incorrect_count).to eq 0
        expect(page.correct_count).to eq 0
        expect(page.trouble).to eq false

        expect(stats.first.spaced_pages).to be_empty

        expect(stats.second).to be_nil
      end
    end

  end

  protected

  def work_task(task:, is_correct:, num_steps: nil)
    is_completed = num_steps.nil? ? true : ->(task, task_step, index) { index < num_steps }
    Preview::WorkTask[task: task, is_completed: is_completed, is_correct: is_correct]
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

  def answer_ids(exercise_content, question_index)
    JSON.parse(exercise_content)['questions'][question_index]['answers'].map{|aa| aa['id'].to_s}
  end

end

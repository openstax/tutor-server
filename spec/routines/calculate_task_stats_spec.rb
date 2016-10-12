require 'rails_helper'
require 'vcr_helper'

RSpec.describe CalculateTaskStats, type: :routine, speed: :slow, vcr: VCR_OPTS do

  before(:all) do
    @number_of_students = 8

    begin
      RSpec::Mocks.setup

      allow_any_instance_of(Tasks::Assistants::IReadingAssistant).to(
        receive(:k_ago_map) { [ [0, 2] ] }
      )
      allow_any_instance_of(Tasks::Assistants::IReadingAssistant).to(
        receive(:num_personalized_exercises_per_page) { 0 }
      )

      @task_plan = FactoryGirl.create :tasked_task_plan, number_of_students: @number_of_students
      @period = @task_plan.owner.periods.first
    ensure
      RSpec::Mocks.teardown
    end
  end

  # Workaround for PostgreSQL bug where the task records
  # stop existing in SELECT FOR UPDATE queries (but not in regular SELECTs)
  # after the transaction rollback that happens in between spec examples
  before(:each) { @task_plan.tasks.each(&:touch) }

  context "with an unworked plan" do

    let(:stats) { described_class.call(tasks: @task_plan.tasks).outputs.stats }

    it "is all nil or zero for an unworked task_plan" do
      expect(stats.first.mean_grade_percent).to be_nil
      expect(stats.first.total_count).to eq(@task_plan.tasks.length)
      expect(stats.first.complete_count).to eq(0)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages[0]
      expect(page.student_count).to eq(0) # no students have worked yet
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages[0]
      expect(spaced_page).to eq page
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

      course = FactoryGirl.create :entity_course, :with_assistants
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

      DistributeTasks.call(task_plan)

      expect(stats.first.complete_count).to eq 0
    end

  end

  context "after task steps are marked as completed" do

    it "records partial/complete status" do
      tasks = @task_plan.tasks.to_a
      first_task = tasks.first
      step = first_task.task_steps.where(
        tasked_type: "Tasks::Models::TaskedReading"
      ).first
      MarkTaskStepCompleted[task_step: step]
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.mean_grade_percent).to be_nil
      expect(stats.first.complete_count).to eq(0)
      expect(stats.first.partially_complete_count).to eq(1)
      expect(stats.first.trouble).to eq false

      first_task.task_steps.each do |ts|
        next if ts.completed?
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      last_task = tasks.last
      MarkTaskStepCompleted[task_step: last_task.task_steps.first]
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(1)
      expect(stats.first.trouble).to eq false
    end

  end

  context "after task steps are marked as correct or incorrect" do

    it "records them" do
      tasks = @task_plan.tasks.to_a
      first_task = tasks.first
      first_task.task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.mean_grade_percent).to eq (100)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(1) # num students with completed task steps
      expect(page['correct_count']).to eq(2)
      expect(page['incorrect_count']).to eq(0)
      expect(page['trouble']).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(1)
      expect(spaced_page['correct_count']).to eq(2)
      expect(spaced_page['incorrect_count']).to eq(0)
      expect(spaced_page['trouble']).to eq false

      second_task = tasks.second
      second_task.task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (50)
      expect(stats.first.complete_count).to eq(2)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(2)
      expect(page['correct_count']).to eq(2)
      expect(page['incorrect_count']).to eq(2)
      expect(page['chapter_section']).to eq([1, 1])
      expect(page['trouble']).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(2)
      expect(spaced_page['correct_count']).to eq(2)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])
      expect(spaced_page['trouble']).to eq false

      third_task = tasks.third
      third_task.task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (67)
      expect(stats.first.complete_count).to eq(3)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(3)
      expect(page['correct_count']).to eq(4)
      expect(page['incorrect_count']).to eq(2)
      expect(page['chapter_section']).to eq([1, 1])
      expect(page['trouble']).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(3)
      expect(spaced_page['correct_count']).to eq(4)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])
      expect(spaced_page['trouble']).to eq false

      fourth_task = tasks.fourth
      fourth_task.task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (75)
      expect(stats.first.complete_count).to eq(4)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(4)
      expect(page['correct_count']).to eq(6)
      expect(page['incorrect_count']).to eq(2)
      expect(page['chapter_section']).to eq([1, 1])
      expect(page['trouble']).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(4)
      expect(spaced_page['correct_count']).to eq(6)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])
      expect(spaced_page['trouble']).to eq false
    end

    # This test assumes that all of these tasks have the same numbers of steps,
    # which is true at least for now
    it "sets trouble to true if >50% incorrect and >25% completed" do
      stats = described_class.call(tasks: @task_plan.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false

      tasks = @task_plan.tasks.to_a
      tasks.first(2).each do |task|
        task.task_steps.each do |ts|
          ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: false] : \
                         MarkTaskStepCompleted[task_step: ts]
        end
      end

      # Only 25% done: no trouble
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false

      tasks.third.task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # Over 25% done: trouble
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq true

      tasks[3..4].each do |task|
        task.task_steps.each do |ts|
          ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: true] : \
                         MarkTaskStepCompleted[task_step: ts]
        end
      end

      # 40% correct: still trouble
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq true

      tasks[5].task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # 50% correct: no more trouble
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false

      tasks[6].task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # 3 out of 7 correct: trouble again
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq true

      tasks[7].task_steps.each do |ts|
        ts.exercise? ? Demo::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # 50% correct: no more trouble
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false
    end

    it "returns detailed stats if :details is true" do
      tasks = @task_plan.tasks.to_a[0..2]

      task_data = {
        selected_answers: [],
        names: []
      }

      tasks.each_with_index do |task, tt|
        task_data[:selected_answers] <<
          task.task_steps.each_with_object([]) do |ts, selected_answers|
            if ts.exercise?
              Demo::AnswerExercise[task_step: ts, is_correct: (tt.even? ? true : false)]
              selected_answers << ts.tasked.answer_id
            else
              MarkTaskStepCompleted[task_step: ts]
            end
          end

        roles = task.taskings.map(&:role)
        users = Role::GetUsersForRoles[roles]
        task_data[:names] << users.map(&:name)
      end

      stats = described_class.call(tasks: @task_plan.reload.tasks, details: true).outputs.stats

      # NOTE: the task data is kind of messed up -- there are 8 tasks with 4 exercises each but
      # only 2 unique exercise URLs (and so only two `exercises` below)

      exercises = stats.first.current_pages.first.exercises

      exercises.each_with_index do |exercise, ii|
        expect(exercise.content).to be_kind_of(String)
        expect(exercise.question_stats.length).to eq 1
        exercise.question_stats.each_with_index do |question_stats, qq|
          expect(question_stats.question_id).to be_kind_of(String)
          expect(question_stats.answered_count).to eq 3
          expect(question_stats.answers.length).to eq 3
          expect(Set.new question_stats.answers).to eq(Set[
            {
              'student_names' => task_data[:names][0],
              'free_response' => 'A sentence explaining all the things!',
              'answer_id' => task_data[:selected_answers][0][ii]
            },
            {
              'student_names' => task_data[:names][1],
              'free_response' => 'A sentence explaining all the wrong things...',
              'answer_id' => task_data[:selected_answers][1][ii]
            },
            {
              'student_names' => task_data[:names][2],
              'free_response' => 'A sentence explaining all the things!',
              'answer_id' => task_data[:selected_answers][2][ii]
            }
          ])

          question_answer_ids = answer_ids(exercise.content, qq)

          expect(question_stats.answer_stats).to eq (question_answer_ids.map do |aid|
            {
              "answer_id" => aid.to_s,
              "selected_count" => task_data[:selected_answers].flatten.count(aid.to_s)
            }
          end)
        end
      end

    end
  end

  context "with multiple course periods" do
    let(:course)   { @task_plan.owner }
    let(:period_2) { FactoryGirl.create :course_membership_period, course: course }
    let(:stats)    { described_class.call(tasks: @task_plan.tasks).outputs.stats }

    before do
      @task_plan.tasks.last(@number_of_students/2).each do |task|
        task.taskings.each do |tasking|
          ::MoveStudent.call(period: period_2, student: tasking.role.student)
        end
      end
    end

    context "if the students were already in the periods before the assignment" do
      before do
        @task_plan.tasks.last(@number_of_students/2).each do |task|
          task.taskings.each do |tasking|
            tasking.period = period_2.to_model
            tasking.save!
          end
        end
      end

      it "splits the students into their periods" do
        expect(stats.first.mean_grade_percent).to be_nil
        expect(stats.first.total_count).to eq(@task_plan.tasks.length/2)
        expect(stats.first.complete_count).to eq(0)
        expect(stats.first.partially_complete_count).to eq(0)
        expect(stats.first.trouble).to eq false

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)
        expect(page.trouble).to eq false

        spaced_page = stats.first.spaced_pages[0]
        expect(spaced_page).to eq page

        expect(stats.second.mean_grade_percent).to be_nil
        expect(stats.second.total_count).to eq(@task_plan.tasks.length/2)
        expect(stats.second.complete_count).to eq(0)
        expect(stats.second.partially_complete_count).to eq(0)
        expect(stats.second.trouble).to eq false

        page = stats.second.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)
        expect(page.trouble).to eq false

        spaced_page = stats.second.spaced_pages[0]
        expect(spaced_page).to eq page
      end

      context 'if a period was archived after the assignment was distributed' do
        before { period_2.to_model.destroy }

        it 'does not show the archived period' do
          expect(stats.first.mean_grade_percent).to be_nil
          expect(stats.first.total_count).to eq(@task_plan.tasks.length/2)
          expect(stats.first.complete_count).to eq(0)
          expect(stats.first.partially_complete_count).to eq(0)
          expect(stats.first.trouble).to eq false

          page = stats.first.current_pages[0]
          expect(page.student_count).to eq(0)
          expect(page.incorrect_count).to eq(0)
          expect(page.correct_count).to eq(0)
          expect(page.trouble).to eq false

          spaced_page = stats.first.spaced_pages[0]
          expect(spaced_page).to eq page

          expect(stats.second).to be_nil
        end
      end
    end

    context "if the students changed periods after the assignment was distributed" do
      it "shows students that changed periods in their original period" do
        expect(stats.first.mean_grade_percent).to be_nil
        expect(stats.first.total_count).to eq(@task_plan.tasks.length)
        expect(stats.first.complete_count).to eq(0)
        expect(stats.first.partially_complete_count).to eq(0)
        expect(stats.first.trouble).to eq false

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)
        expect(page.trouble).to eq false

        spaced_page = stats.first.spaced_pages[0]
        expect(spaced_page).to eq page

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
          expect(stats.first.total_count).to eq(@task_plan.tasks.length)
          expect(stats.first.complete_count).to eq(0)
          expect(stats.first.partially_complete_count).to eq(0)
          expect(stats.first.trouble).to eq false

          page = stats.first.current_pages[0]
          expect(page.student_count).to eq(0)
          expect(page.incorrect_count).to eq(0)
          expect(page.correct_count).to eq(0)
          expect(page.trouble).to eq false

          spaced_page = stats.first.spaced_pages[0]
          expect(spaced_page).to eq page

          expect(stats.second).to be_nil
        end
      end
    end

  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

  def answer_ids(exercise_content, question_index)
    JSON.parse(exercise_content)['questions'][question_index]['answers'].map{|aa| aa['id']}
  end

end

require 'rails_helper'
require 'vcr_helper'

describe CalculateTaskPlanStats, type: :routine, speed: :slow, vcr: VCR_OPTS do

  before(:all) do
    @number_of_students = 8

    DatabaseCleaner.start

    begin
      RSpec::Mocks.setup

      allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [ [0, 2] ] }
      allow(Tasks::Assistants::IReadingAssistant).to receive(:num_personalized_exercises) { 0 }

      @task_plan = FactoryGirl.create :tasked_task_plan, number_of_students: @number_of_students
    ensure
      RSpec::Mocks.teardown
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "with an unworked plan" do

    it "is all nil or zero for an unworked task_plan" do
      stats = CalculateTaskPlanStats.call(plan: @task_plan).outputs.stats
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
        'title' => 'Prokaryotic Cells'})
      page = Content::Routines::ImportPage.call(
        cnx_page: cnx_page, chapter: FactoryGirl.create(:content_chapter),
        book_location: [1, 1]
      ).outputs.page

      course = CreateCourse[name: 'Biology']
      student_profile = FactoryGirl.create(:user_profile)
      student_strategy = User::Strategies::Direct::User.new(student_profile)
      student = User::User.new(strategy: student_strategy)
      AddUserAsPeriodStudent.call(user: student, period: CreatePeriod[course: course])

      task_plan = FactoryGirl.create(
        :tasks_task_plan,
        owner: course,
        settings: { 'page_ids' => [page.id.to_s] },
        assistant: get_assistant(course: course, task_plan_type: 'reading')
      )

      DistributeTasks.call(task_plan)

      stats = CalculateTaskPlanStats.call(plan: task_plan).outputs.stats
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

      stats = CalculateTaskPlanStats.call(plan: @task_plan).outputs.stats
      expect(stats.first.mean_grade_percent).to be_nil
      expect(stats.first.complete_count).to eq(0)
      expect(stats.first.partially_complete_count).to eq(1)
      expect(stats.first.trouble).to eq false

      first_task.task_steps.each do |ts|
        next if ts.completed?
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats

      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)
      expect(stats.first.trouble).to eq false

      last_task = tasks.last
      MarkTaskStepCompleted[task_step: last_task.task_steps.first]
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
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
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
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
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
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
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
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
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
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
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false

      tasks = @task_plan.tasks.to_a
      tasks.first(2).each do |task|
        task.task_steps.each do |ts|
          ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: false] : \
                         MarkTaskStepCompleted[task_step: ts]
        end
      end

      # Only 25% done: no trouble
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false

      tasks.third.task_steps.each do |ts|
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # Over 25% done: trouble
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq true

      tasks[3..4].each do |task|
        task.task_steps.each do |ts|
          ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: true] : \
                         MarkTaskStepCompleted[task_step: ts]
        end
      end

      # 40% correct: still trouble
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq true

      tasks[5].task_steps.each do |ts|
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # 50% correct: no more trouble
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false

      tasks[6].task_steps.each do |ts|
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: false] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # 3 out of 7 correct: trouble again
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq true

      page = stats.first.current_pages.first
      expect(page.trouble).to eq true

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq true

      tasks[7].task_steps.each do |ts|
        ts.exercise? ? Hacks::AnswerExercise[task_step: ts, is_correct: true] : \
                       MarkTaskStepCompleted[task_step: ts]
      end

      # 50% correct: no more trouble
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.trouble).to eq false

      page = stats.first.current_pages.first
      expect(page.trouble).to eq false

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page.trouble).to eq false
    end

    it "returns detailed stats if :details is true" do
      tasks = @task_plan.tasks.to_a
      first_task = tasks.first
      first_tasked_exercise = first_task.task_steps.select{ |ts| ts.tasked.exercise? }.first.tasked

      selected_answers = [[], [], [], []]
      first_task.task_steps.each do |ts|
        if ts.exercise?
          Hacks::AnswerExercise[task_step: ts, is_correct: true]
          selected_answers[0] << ts.tasked.answer_id
        else
          MarkTaskStepCompleted[task_step: ts]
        end
      end
      roles = first_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      first_task_names = users.collect(&:name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 1
        expect(exercise.answers.length).to eq 1
        expect(exercise.answers[0]).to eq(
          'student_names' => first_task_names,
          'free_response' => 'A sentence explaining all the things!',
          'answer_id' => selected_answers[0][ii]
        )
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 1

      second_task = tasks.second
      second_task.task_steps.each do |ts|
        if ts.exercise?
          Hacks::AnswerExercise[task_step: ts, is_correct: false]
          selected_answers[1] << ts.tasked.answer_id
        else
          MarkTaskStepCompleted[task_step: ts]
        end
      end
      roles = second_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      second_task_names = users.collect(&:name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 2
        expect(exercise.answers.length).to eq 2
        expect(Set.new exercise.answers).to eq(Set.new [
          {
            'student_names' => first_task_names,
            'free_response' => 'A sentence explaining all the things!',
            'answer_id' => selected_answers[0][ii]
          },
          {
            'student_names' => second_task_names,
            'free_response' => 'A sentence explaining all the wrong things...',
            'answer_id' => selected_answers[1][ii]
          }
        ])
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 1

      third_task = tasks.third
      third_task.task_steps.each do |ts|
        if ts.exercise?
          Hacks::AnswerExercise[task_step: ts, is_correct: true]
          selected_answers[2] << ts.tasked.answer_id
        else
          MarkTaskStepCompleted[task_step: ts]
        end
      end
      roles = third_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      third_task_names = users.collect(&:name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 3
        expect(exercise.answers.length).to eq 3
        expect(Set.new exercise.answers).to eq(Set.new [
          {
            'student_names' => first_task_names,
            'free_response' => 'A sentence explaining all the things!',
            'answer_id' => selected_answers[0][ii]
          },
          {
            'student_names' => second_task_names,
            'free_response' => 'A sentence explaining all the wrong things...',
            'answer_id' => selected_answers[1][ii]
          },
          {
            'student_names' => third_task_names,
            'free_response' => 'A sentence explaining all the things!',
            'answer_id' => selected_answers[2][ii]
          }
        ])
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 2

      fourth_task = tasks.fourth
      fourth_task.task_steps.each do |ts|
        if ts.exercise?
          Hacks::AnswerExercise[task_step: ts, is_correct: true]
          selected_answers[3] << ts.tasked.answer_id
        else
          MarkTaskStepCompleted[task_step: ts]
        end
      end
      roles = fourth_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      fourth_task_names = users.collect(&:name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 4
        expect(exercise.answers.length).to eq 4
        expect(Set.new exercise.answers).to eq(Set.new [
          {
            'student_names' => first_task_names,
            'free_response' => 'A sentence explaining all the things!',
            'answer_id' => selected_answers[0][ii]
          },
          {
            'student_names' => second_task_names,
            'free_response' => 'A sentence explaining all the wrong things...',
            'answer_id' => selected_answers[1][ii]
          },
          {
            'student_names' => third_task_names,
            'free_response' => 'A sentence explaining all the things!',
            'answer_id' => selected_answers[2][ii]
          },
          {
            'student_names' => fourth_task_names,
            'free_response' => 'A sentence explaining all the things!',
            'answer_id' => selected_answers[3][ii]
          }
        ])
      end

      content_without_selected_count = exercises.first.content.merge(
        'questions' => exercises.first.content.questions.collect do |qq|
          qq.merge('answers' => qq.answers.collect do |aa|
            aa.except('selected_count')
          end)
        end
      )
      expect(content_without_selected_count).to eq first_tasked_exercise.parser.content_hash

      correct_answer = exercises.first.content['questions'].first['answers'].select do |a|
        a.id == first_tasked_exercise.correct_answer_id
      end.first
      expect(correct_answer['selected_count']).to eq 3
    end

  end

  context "with multiple course periods" do
    let!(:course)   { @task_plan.owner }
    let!(:period_2) { CreatePeriod[course: course, name: 'Beta'] }

    before(:each) do
      @task_plan.tasks.last(@number_of_students/2).each do |task|
        task.taskings.each do |tasking|
          ::MoveStudent.call(period: period_2, student: tasking.role.student)
        end
      end
    end

    context "if the students were already in the periods before the assignment" do
      before(:each) do
        @task_plan.tasks.last(@number_of_students/2).each do |task|
          task.taskings.each do |tasking|
            tasking.period = period_2.to_model
            tasking.save!
          end
        end
      end

      it "splits the students into their periods" do
        stats = CalculateTaskPlanStats.call(plan: @task_plan).outputs.stats

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
    end

    context "if the students changed periods after the assignment was distributed" do
      it "shows students that changed periods in their original period" do
        stats = CalculateTaskPlanStats.call(plan: @task_plan).outputs.stats

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

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

end

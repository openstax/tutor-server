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

      page = stats.first.current_pages[0]
      expect(page.student_count).to eq(0) # no students have worked yet
      expect(page.incorrect_count).to eq(0)
      expect(page.correct_count).to eq(0)

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
      student = FactoryGirl.create(:user_profile).entity_user
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
      MarkTaskStepCompleted.call(task_step: step)

      stats = CalculateTaskPlanStats.call(plan: @task_plan).outputs.stats
      expect(stats.first.mean_grade_percent).to be_nil
      expect(stats.first.complete_count).to eq(0)
      expect(stats.first.partially_complete_count).to eq(1)

      first_task.task_steps.each do |ts|
        MarkTaskStepCompleted.call(task_step: ts) unless ts.completed?
      end
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats

      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)

      last_task = tasks.last
      MarkTaskStepCompleted.call(task_step: last_task.task_steps.first)
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (0)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(1)
    end

  end

  context "after task steps are marked as correct or incorrect" do

    it "records them" do
      tasks = @task_plan.tasks.to_a
      first_task = tasks.first
      first_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (100)
      expect(stats.first.complete_count).to eq(1)
      expect(stats.first.partially_complete_count).to eq(0)

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(1) # num students with completed task steps
      expect(page['correct_count']).to eq(2)
      expect(page['incorrect_count']).to eq(0)

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(1)
      expect(spaced_page['correct_count']).to eq(2)
      expect(spaced_page['incorrect_count']).to eq(0)

      second_task = tasks.second
      second_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.free_response = 'a sentence not explaining anything'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (50)
      expect(stats.first.complete_count).to eq(2)
      expect(stats.first.partially_complete_count).to eq(0)

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(2)
      expect(page['correct_count']).to eq(2)
      expect(page['incorrect_count']).to eq(2)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(2)
      expect(spaced_page['correct_count']).to eq(2)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])

      third_task = tasks.third
      third_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (67)
      expect(stats.first.complete_count).to eq(3)
      expect(stats.first.partially_complete_count).to eq(0)

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(3)
      expect(page['correct_count']).to eq(4)
      expect(page['incorrect_count']).to eq(2)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(3)
      expect(spaced_page['correct_count']).to eq(4)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])

      fourth_task = tasks.fourth
      fourth_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload).outputs.stats
      expect(stats.first.mean_grade_percent).to eq (75)
      expect(stats.first.complete_count).to eq(4)
      expect(stats.first.partially_complete_count).to eq(0)

      page = stats.first.current_pages.first
      expect(page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(page['student_count']).to eq(4)
      expect(page['correct_count']).to eq(6)
      expect(page['incorrect_count']).to eq(2)
      expect(page['chapter_section']).to eq([1, 1])

      spaced_page = stats.first.spaced_pages.first
      expect(spaced_page['title']).to eq("Newton's First Law of Motion: Inertia")
      expect(spaced_page['student_count']).to eq(4)
      expect(spaced_page['correct_count']).to eq(6)
      expect(spaced_page['incorrect_count']).to eq(2)
      expect(spaced_page['chapter_section']).to eq([1, 1])
    end

    it "returns detailed stats if :details is true" do
      tasks = @task_plan.tasks.to_a
      first_task = tasks.first
      first_tasked_exercise = first_task.task_steps.select{ |ts| ts.tasked.exercise? }.first.tasked

      selected_answers = [[], [], [], []]
      first_task.task_steps.each { |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
          selected_answers[0] << ts.tasked.answer_id
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      roles = first_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      first_task_names = UserProfile::SearchProfiles[search: users].items.collect(&:full_name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 1
        expect(exercise.answers.length).to eq 1
        expect(exercise.answers[0]).to eq(
          'student_names' => first_task_names,
          'free_response' => 'a sentence explaining all the things',
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
      second_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.free_response = 'a sentence not explaining anything'
          ts.tasked.save!
          selected_answers[1] << ts.tasked.answer_id
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      roles = second_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      second_task_names = UserProfile::SearchProfiles[search: users].items.collect(&:full_name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 2
        expect(exercise.answers.length).to eq 2
        expect(Set.new exercise.answers).to eq(Set.new [
          {
            'student_names' => first_task_names,
            'free_response' => 'a sentence explaining all the things',
            'answer_id' => selected_answers[0][ii]
          },
          {
            'student_names' => second_task_names,
            'free_response' => 'a sentence not explaining anything',
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
      third_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
          selected_answers[2] << ts.tasked.answer_id
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      roles = third_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      third_task_names = UserProfile::SearchProfiles[search: users].items.collect(&:full_name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 3
        expect(exercise.answers.length).to eq 3
        expect(Set.new exercise.answers).to eq(Set.new [
          {
            'student_names' => first_task_names,
            'free_response' => 'a sentence explaining all the things',
            'answer_id' => selected_answers[0][ii]
          },
          {
            'student_names' => second_task_names,
            'free_response' => 'a sentence not explaining anything',
            'answer_id' => selected_answers[1][ii]
          },
          {
            'student_names' => third_task_names,
            'free_response' => 'a sentence explaining all the things',
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
      fourth_task.task_steps.each{ |ts|
        if ts.tasked.exercise?
          ts.tasked.answer_id = ts.tasked.correct_answer_id
          ts.tasked.free_response = 'a sentence explaining all the things'
          ts.tasked.save!
          selected_answers[3] << ts.tasked.answer_id
        end
        MarkTaskStepCompleted.call(task_step: ts)
      }
      roles = fourth_task.taskings.collect(&:role)
      users = Role::GetUsersForRoles[roles]
      fourth_task_names = UserProfile::SearchProfiles[search: users].items.collect(&:full_name)

      stats = CalculateTaskPlanStats.call(plan: @task_plan.reload, details: true).outputs.stats
      exercises = stats.first.current_pages.first.exercises
      exercises.each_with_index do |exercise, ii|
        expect(exercise.answered_count).to eq 4
        expect(exercise.answers.length).to eq 4
        expect(Set.new exercise.answers).to eq(Set.new [
          {
            'student_names' => first_task_names,
            'free_response' => 'a sentence explaining all the things',
            'answer_id' => selected_answers[0][ii]
          },
          {
            'student_names' => second_task_names,
            'free_response' => 'a sentence not explaining anything',
            'answer_id' => selected_answers[1][ii]
          },
          {
            'student_names' => third_task_names,
            'free_response' => 'a sentence explaining all the things',
            'answer_id' => selected_answers[2][ii]
          },
          {
            'student_names' => fourth_task_names,
            'free_response' => 'a sentence explaining all the things',
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

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)

        spaced_page = stats.first.spaced_pages[0]
        expect(spaced_page).to eq page

        expect(stats.second.mean_grade_percent).to be_nil
        expect(stats.second.total_count).to eq(@task_plan.tasks.length/2)
        expect(stats.second.complete_count).to eq(0)
        expect(stats.second.partially_complete_count).to eq(0)

        page = stats.second.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)

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

        page = stats.first.current_pages[0]
        expect(page.student_count).to eq(0)
        expect(page.incorrect_count).to eq(0)
        expect(page.correct_count).to eq(0)

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

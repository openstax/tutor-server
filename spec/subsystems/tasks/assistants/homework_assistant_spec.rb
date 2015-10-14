require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, type: :assistant,
                                                     speed: :slow,
                                                     vcr: VCR_OPTS do

  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant')
  }

  let!(:chapter) {
    FactoryGirl.create :content_chapter, title: "Forces and Newton's Laws of Motion"
  }

  let!(:ecosystem) {
    content_ecosystem = chapter.book.ecosystem
    strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
    ::Content::Ecosystem.new(strategy: strategy)
  }

  let!(:cnx_page_hashes) { [
    { 'id' => '1bb611e9-0ded-48d6-a107-fbb9bd900851', 'title' => 'Introduction' },
    { 'id' => '95e61258-2faf-41d4-af92-f62e1414175a', 'title' => 'Force' }
  ] }

  let!(:cnx_pages) {
    cnx_page_hashes.collect do |hash|
      OpenStax::Cnx::V1::Page.new(hash: hash)
    end
  }

  let!(:content_pages)     {
    cnx_pages.collect.with_index do |cnx_page, ii|
      content_page = Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        chapter: chapter,
        book_location: [8, ii+1]
      ).outputs.page.reload
    end
  }

  let!(:pools) {
    Content::Routines::PopulateExercisePools[book: chapter.book]
  }

  let!(:pages)     {
    content_pages.collect do |content_page|
      strategy = ::Content::Strategies::Direct::Page.new(content_page)
      ::Content::Page.new(strategy: strategy)
    end
  }

  let!(:exercises) {
    pools = ecosystem.homework_core_pools(pages: pages)

    pools.collect{ |pool| pool.exercises }.flatten.sort_by{|ex| ex.uid}
  }

  let!(:teacher_selected_exercises) { exercises[1..5] }
  let!(:teacher_selected_exercise_ids) { teacher_selected_exercises.collect{|e| e.id.to_s} }

  let!(:tutor_selected_exercise_count) { 4 }
  let!(:personalized_exercise_count) { 2 }

  let!(:assignment_exercise_count) { teacher_selected_exercise_ids.count +
                                     tutor_selected_exercise_count +
                                     personalized_exercise_count }

  let!(:task_plan) {
    FactoryGirl.build(:tasks_task_plan,
      assistant: assistant,
      content_ecosystem_id: ecosystem.id,
      description: "Hello!",
      settings: {
        exercise_ids: teacher_selected_exercise_ids,
        exercises_count_dynamic: tutor_selected_exercise_count
      },
      num_tasking_plans: 0
    )
  }

  let!(:num_taskees) { 3 }

  let!(:taskee_profiles) {
    num_taskees.times.collect do
      FactoryGirl.create(:user_profile)
    end
  }

  let!(:taskee_users) {
    taskee_profiles.collect do |profile|
      strategy = User::Strategies::Direct::User.new(profile)
      User::User.new(strategy: strategy).tap do |user|
        AddUserAsPeriodStudent.call(user: user, period: period)
      end
    end
  }

  let!(:tasking_plans) {
    tps = taskee_profiles.collect do |taskee|
      task_plan.tasking_plans <<
        FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee
        )
    end

    task_plan.save!
    tps
  }

  let!(:course) {
    task_plan.owner.tap do |course|
      AddEcosystemToCourse[course: course, ecosystem: ecosystem]
    end
  }
  let!(:period) { CreatePeriod[course: course] }

  it "creates the expected assignments" do
    #puts "teacher_selected_exercises = #{teacher_selected_exercises.collect{|ex| ex.uid}}"

    allow(Tasks::Assistants::HomeworkAssistant).
      to receive(:k_ago_map) { [ [0,tutor_selected_exercise_count] ] }
    allow(Tasks::Assistants::HomeworkAssistant).
      to receive(:num_personalized_exercises) { personalized_exercise_count }

    entity_tasks = DistributeTasks.call(task_plan).outputs.entity_tasks

    ## it "sets description, task type, and feedback_at"
    entity_tasks.each do |entity_task|
      entity_task.reload.reload
      task = entity_task.task
      expect(task.description).to eq("Hello!")
      expect(task.homework?).to be_truthy
      expect(task.feedback_at).to eq(task.due_at)
    end

    ## it "creates one task per taskee"
    expect(entity_tasks.count).to eq(taskee_profiles.count)

    ## it "assigns each task to one role"
    entity_tasks.each do |entity_task|
      expect(entity_task.taskings.count).to eq(1)
    end
    expected_roles = taskee_users.collect{ |taskee| Role::GetDefaultUserRole[taskee] }
    expect(entity_tasks.collect{|t| t.taskings.first.role}).to eq expected_roles

    ## it "assigns the correct number of exercises"
    entity_tasks.each do |entity_task|
      expect(entity_task.task.task_steps.count).to eq(assignment_exercise_count)
    end

    ## it "assigns the teacher-selected exercises as the task's core exercises"
    entity_tasks.each do |entity_task|
      core_task_steps = entity_task.task.core_task_steps
      expect(core_task_steps.count).to eq(teacher_selected_exercises.count)

      core_task_steps.each_with_index do |task_step, ii|
        tasked_exercise = task_step.tasked

        exercise = teacher_selected_exercises[ii]

        expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
        expect(tasked_exercise.url).to eq(exercise.url)
        expect(tasked_exercise.title).to eq(exercise.title)
        expect(tasked_exercise.content).to eq(exercise.content)
      end
    end

    ## it "assigns the tutor-selected spaced practice exercises"
    entity_tasks.each do |entity_task|
      spaced_practice_task_steps = entity_task.task.spaced_practice_task_steps
      expect(spaced_practice_task_steps.count).to eq(tutor_selected_exercise_count)

      spaced_practice_task_steps.each do |task_step|
        tasked_exercise = task_step.tasked
        expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
      end
    end

    ## it "assigns personalized exercise placeholders"
    entity_tasks.each do |entity_task|
      personalized_task_steps = entity_task.task.personalized_task_steps
      expect(personalized_task_steps.count).to eq(personalized_exercise_count)

      personalized_task_steps.each do |task_step|
        tasked_placeholder = task_step.tasked
        expect(tasked_placeholder).to be_a(Tasks::Models::TaskedPlaceholder)
        expect(tasked_placeholder.exercise_type?).to be_truthy
      end
    end

  end

end

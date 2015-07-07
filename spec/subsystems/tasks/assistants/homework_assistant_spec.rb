require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, type: :assistant,
                                                     speed: :slow,
                                                     vcr: VCR_OPTS do

  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant')
  }

  let!(:book_part) {
    FactoryGirl.create :content_book_part, title: "Forces and Newton's Laws of Motion"
  }

  let!(:cnx_page_hashes) { [
    { 'id' => '1bb611e9-0ded-48d6-a107-fbb9bd900851', 'title' => 'Introduction' },
    { 'id' => '95e61258-2faf-41d4-af92-f62e1414175a', 'title' => 'Force' }
  ] }

  let!(:cnx_pages) { cnx_page_hashes.each_with_index.collect do |hash, i|
    OpenStax::Cnx::V1::Page.new(hash: hash, chapter_section: [8, i+1])
  end }

  let!(:pages)     { cnx_pages.collect do |cnx_page|
    Content::Routines::ImportPage.call(
      cnx_page:  cnx_page,
      book_part: book_part
    ).outputs.page
  end }

  let!(:exercises) {
    page_los = Content::GetLos[page_ids: pages.map(&:id)]

    page_exercises = Content::Routines::SearchExercises[tag: page_los, match_count: 1]

    review_exercises = Content::Models::Exercise.joins{exercise_tags.tag}
                                                .where{exercise_tags.tag.value.eq 'ost-chapter-review'}
                                                .where{id.in page_exercises.map(&:id)}

    exercises = Content::Models::Exercise.joins{exercise_tags.tag}
                                         .where{exercise_tags.tag.value.in ['problem', 'concept']}
                                         .where{id.in review_exercises.map(&:id)}

    exercises = exercises.sort_by{|ex| ex.uid}
    exercises
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
      description: "Hello!",
      settings: {
        exercise_ids: teacher_selected_exercise_ids,
        exercises_count_dynamic: tutor_selected_exercise_count
      },
      num_tasking_plans: 0
    )
  }

  let!(:num_taskees) { 3 }

  let!(:taskees) { num_taskees.times.collect do
    user = Entity::User.create
    AddUserAsPeriodStudent.call(user: user, period: period)
    user
  end }

  let!(:tasking_plans) {
    tps = taskees.collect do |taskee|
      task_plan.tasking_plans <<
        FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee
        )
    end

    task_plan.save
    tps
  }

  let!(:course) { task_plan.owner }
  let!(:period) { CreatePeriod[course: course] }

  it "creates the expected assignments" do
    #puts "teacher_selected_exercises = #{teacher_selected_exercises.collect{|ex| ex.uid}}"

    allow(Tasks::Assistants::HomeworkAssistant).
      to receive(:k_ago_map) { [ [0,tutor_selected_exercise_count] ] }
    allow(Tasks::Assistants::HomeworkAssistant).
      to receive(:num_personalized_exercises) { personalized_exercise_count }

    tasks = DistributeTasks.call(task_plan).outputs.tasks

    ## it "sets description, task type, and feedback_at"
    tasks.each do |task|
      expect(task.description).to eq("Hello!")
      expect(task.homework?).to be_truthy
      expect(task.feedback_at).to eq(task.due_at)
    end

    ## it "creates one task per taskee"
    expect(tasks.count).to eq(taskees.count)

    ## it "assigns each task to one role"
    tasks.each do |task|
      expect(task.taskings.count).to eq(1)
    end
    expected_roles = taskees.collect{ |taskee| Role::GetDefaultUserRole[taskee] }
    expect(tasks.collect{|t| t.taskings.first.role}).to eq expected_roles

    ## it "assigns the correct number of exercises"
    tasks.each do |task|
      expect(task.task_steps.count).to eq(assignment_exercise_count)
    end

    ## it "assigns the teacher-selected exercises as the task's core exercises"
    tasks.each do |task|
      core_task_steps = task.core_task_steps
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
    tasks.each do |task|
      spaced_practice_task_steps = task.spaced_practice_task_steps
      expect(spaced_practice_task_steps.count).to eq(tutor_selected_exercise_count)

      spaced_practice_task_steps.each do |task_step|
        tasked_exercise = task_step.tasked
        expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
      end
    end

    ## it "assigns personalized exericse placeholders"
    tasks.each do |task|
      personalized_task_steps = task.personalized_task_steps
      expect(personalized_task_steps.count).to eq(personalized_exercise_count)

      personalized_task_steps.each do |task_step|
        tasked_placeholder = task_step.tasked
        expect(tasked_placeholder).to be_a(Tasks::Models::TaskedPlaceholder)
        expect(tasked_placeholder.exercise_type?).to be_truthy
      end
    end

  end

end

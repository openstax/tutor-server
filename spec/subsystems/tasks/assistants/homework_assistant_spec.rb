require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, type: :assistant,
                                                     speed: :slow,
                                                     vcr: VCR_OPTS do

  before(:each) { OpenStax::Exercises::V1.use_real_client }

  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::HomeworkAssistant'
    )
  }

  let!(:book_part) {
    FactoryGirl.create :content_book_part,
                       title: "Forces and Newton's Laws of Motion"
  }

  let!(:cnx_page_hashes) { [
    { 'id' => '1491e74e-ed39-446f-a602-e7ab881af101@9',
      'title' => 'Introduction' },
    { 'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083@11',
      'title' => 'Force' }
  ] }

  let!(:cnx_pages) { cnx_page_hashes.each_with_index.collect do |hash, i|
    OpenStax::Cnx::V1::Page.new(hash: hash, chapter_section: "8.#{i+1}")
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
    #puts "exercises = #{exercises.map(&:uid)}"
    exercises
  }

  let!(:teacher_selected_exercises) { exercises[1..5] }
  let!(:teacher_selected_exercise_ids) { teacher_selected_exercises.collect{|e| e.id.to_s} }

  let!(:tutor_selected_exercise_count) { 4 } # Adjust if spaced practice changes

  let!(:assignment_exercise_count) { teacher_selected_exercise_ids.count + tutor_selected_exercise_count }

  let!(:task_plan) {
    FactoryGirl.create(:tasks_task_plan,
      assistant: assistant,
      settings: {
        exercise_ids: teacher_selected_exercise_ids,
        exercises_count_dynamic: tutor_selected_exercise_count,
        description: "Hello!"
      }
    )
  }

  let!(:num_taskees) { 3 }

  let!(:taskees) { num_taskees.times.collect{ Entity::User.create } }

  let!(:tasking_plans) {
    taskees.collect do |taskee|
      task_plan.tasking_plans <<
        FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee
        )
    end
  }

  it "creates the expected assignments" do
    #puts "teacher_selected_exercises = #{teacher_selected_exercises.collect{|ex| ex.uid}}"

    allow(Tasks::Assistants::HomeworkAssistant).
      to receive(:k_ago_map) { [ [0,tutor_selected_exercise_count] ] }

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
    end
  end

end

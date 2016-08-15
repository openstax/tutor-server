require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, type: :assistant,
                                                     speed: :slow,
                                                     vcr: VCR_OPTS do

  before(:all) do
    @assistant = \
      FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant')
  end

  context "for Introduction and Force" do
    before(:all) do
      cnx_page_hashes = [
        { 'id' => '1bb611e9-0ded-48d6-a107-fbb9bd900851', 'title' => 'Introduction' },
        { 'id' => '95e61258-2faf-41d4-af92-f62e1414175a', 'title' => 'Force' }
      ]

      @intro_step_gold_data = {
        klass: Tasks::Models::TaskedReading,
        title: "Forces and Newton's Laws of Motion",
        related_content: [{title: "Forces and Newton's Laws of Motion",
                           book_location: [8, 1]}]
      }

      @core_step_gold_data = [
        @intro_step_gold_data,
        { klass: Tasks::Models::TaskedReading,
          title: "Force",
          related_content: [{title: "Force",
                             book_location: [8, 2]}] }
      ]

      @spaced_practice_step_gold_data = [
        { klass: Tasks::Models::TaskedExercise,
          title: nil,
          related_content: [{title: "Force",
                            book_location: [8, 2]}] },
        { klass: Tasks::Models::TaskedExercise,
          title: nil,
          related_content: [{title: "Force",
                             book_location: [8, 2]}] },
      ]

      @personalized_step_gold_data = [
        { klass: Tasks::Models::TaskedPlaceholder,
          title: nil,
          related_content: [] }
      ]

      @task_step_gold_data = \
        @core_step_gold_data + @spaced_practice_step_gold_data + @personalized_step_gold_data

      cnx_pages = cnx_page_hashes.map do |hash|
        OpenStax::Cnx::V1::Page.new(hash: hash)
      end

      chapter = FactoryGirl.create :content_chapter, title: "Forces and Newton's Laws of Motion"

      ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(chapter.book.ecosystem)
      @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)

      @content_pages = VCR.use_cassette(
                 'Tasks_Assistants_HomeworkAssistant/for_Introduction_and_Force/with_pages',
                 VCR_OPTS
               ) do
        cnx_pages.map.with_index do |cnx_page, ii|
          Content::Routines::ImportPage.call(
            cnx_page:  cnx_page,
            chapter: chapter,
            book_location: [8, ii+1]
          ).outputs.page.reload
        end
      end

      @pages = @content_pages.map{ |content_page| Content::Page.new(strategy: content_page.wrap) }

      Content::Routines::PopulateExercisePools[book: chapter.book]
    end

    let(:core_pools)                     { @ecosystem.homework_core_pools(pages: @pages) }
    let(:core_exercises)                 { core_pools.flat_map(&:exercises).sort_by(&:uid) }

    let(:dynamic_pools)                  { @ecosystem.homework_dynamic_pools(pages: @pages) }
    let(:dynamic_exercises)              { dynamic_pools.flat_map(&:exercises).sort_by(&:uid) }

    let(:teacher_selected_exercises)     { core_exercises[1..5] }
    let(:teacher_selected_exercise_ids)  { teacher_selected_exercises.map{|e| e.id.to_s} }

    let(:tutor_selected_exercise_count)  { 4 }
    let(:personalized_exercise_count)    { 2 }
    let(:spaced_practice_exercise_count) do
      tutor_selected_exercise_count - personalized_exercise_count
    end

    let(:assignment_exercise_count)     do
      teacher_selected_exercise_ids.count + tutor_selected_exercise_count
    end

    let(:task_plan)                     do
      FactoryGirl.build(:tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: @ecosystem.id,
        description: "Hello!",
        is_feedback_immediate: true,
        settings: {
          exercise_ids: teacher_selected_exercise_ids,
          exercises_count_dynamic: tutor_selected_exercise_count
        },
        num_tasking_plans: 0
      )
    end

    let(:course) do
      task_plan.owner.tap do |course|
        AddEcosystemToCourse[course: course, ecosystem: @ecosystem]
      end
    end
    let(:period) { CreatePeriod[course: course] }

    let(:num_taskees) { 3 }

    let(:taskee_users) do
      num_taskees.times.map do
        user = FactoryGirl.create(:user)
        AddUserAsPeriodStudent.call(user: user, period: period)
        user
      end
    end

    let!(:tasking_plans) do
      tps = taskee_users.map do |taskee|
        task_plan.tasking_plans << FactoryGirl.create(
          :tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee.to_model
        )
      end

      task_plan.save!
      tps
    end

    it "creates the expected assignments" do
      #puts "teacher_selected_exercises = #{teacher_selected_exercises.map(&:uid)}"

      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:k_ago_map) { [ [0, spaced_practice_exercise_count] ] }
      )
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:num_personalized_exercises) { personalized_exercise_count }
      )

      tasks = DistributeTasks.call(task_plan).outputs.tasks

      ## it "sets description, task type, and feedback_at"
      tasks.each do |task|
        expect(task.description).to eq("Hello!")
        expect(task.homework?).to be_truthy
        # feedback_at == nil because the task plan was set to immediate_feedback
        expect(task.feedback_at).to be_nil
      end

      ## it "creates one task per taskee"
      expect(tasks.count).to eq(taskee_users.count)

      ## it "assigns each task to one role"
      tasks.each do |task|
        expect(task.taskings.count).to eq(1)
      end
      expected_roles = taskee_users.map{ |taskee| Role::GetDefaultUserRole[taskee] }
      expect(tasks.map{|t| t.taskings.first.role}).to match_array expected_roles

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
        expect(spaced_practice_task_steps.count).to eq(spaced_practice_exercise_count)

        spaced_practice_task_steps.each do |task_step|
          tasked_exercise = task_step.tasked
          expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
        end
      end

      ## it "assigns personalized exercise placeholders"
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

    it "does not assign excluded dynamic exercises" do
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:k_ago_map) { [ [0, spaced_practice_exercise_count] ] }
      )
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:num_personalized_exercises) { personalized_exercise_count }
      )

      eligible_exercises = dynamic_exercises - teacher_selected_exercises
      eligible_exercises.each do |exercise|
        CourseContent::Models::ExcludedExercise.create!(course: course,
                                                        exercise_number: exercise.number)
      end

      tasks = DistributeTasks.call(task_plan).outputs.tasks

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

        spaced_practice_task_steps = task.spaced_practice_task_steps
        expect(spaced_practice_task_steps.count).to eq 0

        personalized_task_steps = task.personalized_task_steps
        expect(personalized_task_steps.count).to eq(personalized_exercise_count)

        personalized_task_steps.each do |task_step|
          tasked_placeholder = task_step.tasked
          expect(tasked_placeholder).to be_a(Tasks::Models::TaskedPlaceholder)
          expect(tasked_placeholder.exercise_type?).to be_truthy
        end
      end
    end

    it "does not assign the same spaced practice exercise twice in the same assignment" do
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:k_ago_map) { [ [0, spaced_practice_exercise_count],
                                [0, spaced_practice_exercise_count] ] }
      )
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:num_personalized_exercises) { personalized_exercise_count }
      )

      eligible_exercises = dynamic_exercises - teacher_selected_exercises
      unexcluded_exercise = eligible_exercises.first.to_model
      eligible_exercises[1..-1].each do |exercise|
        CourseContent::Models::ExcludedExercise.create!(course: course,
                                                        exercise_number: exercise.number)
      end

      tasks = DistributeTasks.call(task_plan).outputs.tasks

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

        spaced_practice_task_steps = task.spaced_practice_task_steps
        expect(spaced_practice_task_steps.count).to eq 1
        expect(spaced_practice_task_steps.first.tasked.exercise).to eq unexcluded_exercise

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

end

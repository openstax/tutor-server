require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::IReadingAssistant, type: :assistant,
                                                     speed: :slow,
                                                     vcr: VCR_OPTS do

  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant')
  }

  let!(:book_part) {
    FactoryGirl.create :content_book_part, title: "Forces and Newton's Laws of Motion"
  }

  context "for Introduction and Force" do
    let!(:cnx_page_hashes) { [
      { 'id' => '1bb611e9-0ded-48d6-a107-fbb9bd900851', 'title' => 'Introduction' },
      { 'id' => '95e61258-2faf-41d4-af92-f62e1414175a', 'title' => 'Force' }
    ] }

    let!(:core_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedReading,
          title: "Forces and Newton's Laws of Motion",
          related_content: [{title: "Forces and Newton's Laws of Motion",
                             chapter_section: [8, 1]}] },
        { klass: Tasks::Models::TaskedReading,
          title: "Force",
          related_content: [{title: "Force", chapter_section: [8, 2]}] }
      ]
    }

    let!(:spaced_practice_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedExercise,
          title: nil,
          related_content: [{title: "Force", chapter_section: [8, 2]}] },
        { klass: Tasks::Models::TaskedExercise,
          title: nil,
          related_content: [{title: "Force", chapter_section: [8, 2]}] },
      ]
    }

    let!(:personalized_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedPlaceholder,
          title: nil,
          related_content: [] }
      ]
    }

    let!(:task_step_gold_data) {
      core_step_gold_data + spaced_practice_step_gold_data + personalized_step_gold_data
    }

    let!(:cnx_pages) { cnx_page_hashes.each_with_index.collect do |hash, i|
      OpenStax::Cnx::V1::Page.new(hash: hash, chapter_section: [8, i+1])
    end }

    let!(:pages)     { cnx_pages.collect do |cnx_page|
      Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        book_part: book_part
      ).outputs.page
    end }

    let!(:task_plan) {
      FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
        settings: { page_ids: pages.collect{ |page| page.id.to_s } }
      )
    }

    let!(:course) { task_plan.owner }
    let!(:period) { CreatePeriod[course: course] }

    let!(:num_taskees) { 3 }

    let!(:taskees) { num_taskees.times.collect do
      user = Entity::User.create
      AddUserAsPeriodStudent.call(user: user, period: period)
      user
    end }

    let!(:tasking_plans) {
      taskees.collect{ |tt|
        task_plan.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target: tt
        )
      }
    }

    it 'splits a CNX module into many different steps and assigns them with immediate feedback' do
      allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [[0, 2]]}

      tasks = DistributeTasks.call(task_plan).outputs.tasks
      expect(tasks.length).to eq num_taskees

      tasks.each do |task|
        expect(task.taskings.length).to eq 1
        expect(task.feedback_at).to be <= Time.now

        task_steps = task.task_steps
        expect(task_steps.count).to eq(task_step_gold_data.count)
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          next if task_step.placeholder?

          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
          expect(task_step.related_content).to eq(task_step_gold_data[ii][:related_content])
        end

        core_task_steps = task.core_task_steps
        expect(core_task_steps.count).to eq(core_step_gold_data.count)

        core_task_steps.each_with_index do |task_step, i|
          page = (i == 0) ? pages.first : pages.last

          expect(task_step.tasked.content).not_to include('snap-lab')

          if task_step.tasked_type.demodulize == 'TaskedExercise'
            expect(page.content).not_to include(task_step.tasked.content)
          end

          if task_step.tasked_type.demodulize == 'TaskedReading'
            expect(task_step.tasked.chapter_section).to eq(page.chapter_section)
          end

          other_task_steps = core_task_steps.reject{|ts| ts == task_step}
          other_task_steps.each do |other_step|
            expect(task_step.tasked.content).not_to(
              include(other_step.tasked.content)
            )
          end

        end

        expect(task.spaced_practice_task_steps.count).to eq(spaced_practice_step_gold_data.count)

        expect(task.personalized_task_steps.count).to eq(personalized_step_gold_data.count)
      end

      expected_roles = taskees.collect{ |t| Role::GetDefaultUserRole[t] }
      expect(tasks.collect{|t| t.taskings.first.role}).to eq expected_roles
    end
  end

  context "for Inertia" do
    let!(:cnx_page_hash) { {
      'id' => '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
      'title' => "Newton's First Law of Motion: Inertia"
    } }

    let!(:core_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedReading,
          title: "Newton's First Law of Motion: Inertia" },
        { klass: Tasks::Models::TaskedVideo,
          title: nil },
        { klass: Tasks::Models::TaskedExercise,
          title: nil },
        { klass: Tasks::Models::TaskedInteractive,
          title: nil },
        { klass: Tasks::Models::TaskedExercise,
          title: nil }
      ]
    }

    let!(:spaced_practice_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedExercise,
          title: nil },
        { klass: Tasks::Models::TaskedExercise,
          title: nil },
      ]
    }

    let!(:task_step_gold_data) {
      core_step_gold_data + spaced_practice_step_gold_data
    }

    let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

    let!(:page) {
      Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        book_part: book_part
      ).outputs.page
    }

    let!(:task_plan) {
      FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
        settings: { page_ids: [page.id.to_s] }
      )
    }

    let!(:course) { task_plan.owner }
    let!(:period) { CreatePeriod[course: course] }

    let!(:num_taskees) { 3 }

    let!(:taskees) { num_taskees.times.collect do
      user = Entity::User.create
      AddUserAsPeriodStudent.call(user: user, period: period)
      user
    end }

    let!(:tasking_plans) {
      taskees.collect{ |t|
        task_plan.tasking_plans << FactoryGirl.create(
          :tasks_tasking_plan, task_plan: task_plan, target: t
        )
      }
    }

    it 'is split into different task steps with immediate feedback' do
      allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [[0, 2]]}
      allow(Tasks::Assistants::IReadingAssistant).to receive(:num_personalized_exercises) { 0 }

      tasks = DistributeTasks.call(task_plan).outputs.tasks
      tasks.each do |task|
        expect(task.taskings.length).to eq 1
        expect(task.feedback_at).to be <= Time.now

        task_steps = task.task_steps

        expect(task_steps.count).to eq task_step_gold_data.count
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
        end
      end
    end

  end

end

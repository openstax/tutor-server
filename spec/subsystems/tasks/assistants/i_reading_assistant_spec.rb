require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::IReadingAssistant, :type => :assistant, :vcr => VCR_OPTS do

  before(:each) { OpenStax::Exercises::V1.use_real_client }
  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::IReadingAssistant'
    )
  }

  let!(:book_part) { FactoryGirl.create :content_book_part }

  context "for Force version 11" do
    let!(:cnx_page_hash) { { 'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083@11',
                             'title' => 'Force',
                             'path' => '8.6' } }

    let!(:core_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedReading,
          title: "TBD; Section Learning Objectives; Defining Force and Dynamics"},
        { klass: Tasks::Models::TaskedVideo,
          title: "A Note called Watch Physics with YouTube Embedded"},
        { klass: Tasks::Models::TaskedReading,
          title: nil},
        { klass: Tasks::Models::TaskedReading,
          title: "Mars Probe Explosion"},
        { klass: Tasks::Models::TaskedExercise,
          title: nil},
        { klass: Tasks::Models::TaskedReading,
          title: "Free-body Diagrams and Examples of Forces"}
      ]
    }

    let!(:spaced_practice_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedPlaceholder,
          title: nil},
        { klass: Tasks::Models::TaskedPlaceholder,
          title: nil},
      ]
    }

    let!(:task_step_gold_data) {
      core_step_gold_data + spaced_practice_step_gold_data
    }

    let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

    let!(:page)     {
      Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        book_part: book_part
      ).outputs.page
    }

    let!(:task_plan) {
      FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
        settings: { page_ids: [page.id] }
      )
    }

    let!(:num_taskees) { 3 }

    let!(:taskees) { num_taskees.times.collect{ Entity::User.create } }

    let!(:tasking_plans) {
      taskees.collect{ |t|
        task_plan.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target: t
        )
      }
    }

    it 'splits a CNX module into many different steps and assigns them' do
      tasks = DistributeTasks.call(task_plan).outputs.tasks
      expect(tasks.length).to eq num_taskees

      tasks.each do |task|
        expect(task.taskings.length).to eq 1

        expect(task.core_task_steps.count).to eq(core_step_gold_data.count)
        expect(task.spaced_practice_task_steps.count).to eq(spaced_practice_step_gold_data.count)

        task_steps = task.task_steps
        expect(task_steps.count).to eq(task_step_gold_data.count)

        non_placeholder_task_steps = task_steps.reject{|ts| ts.tasked_type.demodulize == 'TaskedPlaceholder'}

        non_placeholder_task_steps.each do |task_step|
          expect(task_step.tasked.content).not_to include('snap-lab')

          if task_step.tasked_type.demodulize == 'TaskedExercise'
            expect(page.content).not_to include(task_step.tasked.content)
          end

          if task_step.tasked_type.demodulize == 'TaskedReading'
            expect(task_step.tasked.path).to eq('8.6')
          end

          other_task_steps = non_placeholder_task_steps.reject{|ts| ts == task_step}
          other_task_steps.each do |other_step|
            expect(task_step.tasked.content).not_to(
              include(other_step.tasked.content)
            )
          end

        end

        task_steps.each_with_index do |task_step, ii|
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
        end
      end

      expected_roles = taskees.collect{ |t| Role::GetDefaultUserRole[t] }
      expect(tasks.collect{|t| t.taskings.first.role}).to eq expected_roles
    end
  end

  context "for Inertia version 11" do
    let!(:cnx_page_hash) { {
      'id' => '61445f78-00e2-45ae-8e2c-461b17d9b4fd@11',
      'title' => "Newton's First Law of Motion: Inertia",
      'path' => 'anything'
    } }

    let!(:core_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedReading },
        { klass: Tasks::Models::TaskedVideo },
        { klass: Tasks::Models::TaskedExercise },
        { klass: Tasks::Models::TaskedInteractive },
        { klass: Tasks::Models::TaskedReading },
        { klass: Tasks::Models::TaskedExercise },
        { klass: Tasks::Models::TaskedReading }
      ]
    }

    let!(:spaced_practice_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedPlaceholder },
        { klass: Tasks::Models::TaskedPlaceholder },
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
    let!(:taskees) { 3.times.collect{ FactoryGirl.create(:user_profile) } }
    let!(:tasking_plans) { taskees.collect{ |t|
      task_plan.tasking_plans << FactoryGirl.create(
        :tasks_tasking_plan, task_plan: task_plan, target: t
      )
    }

    let!(:num_taskees) { 3 }

    let!(:taskees) { num_taskees.times.collect{ FactoryGirl.create(:user) } }

    let!(:tasking_plans) {
      taskees.collect{ |t|
        task_plan.tasking_plans << FactoryGirl.create(
          :tasks_tasking_plan, task_plan: task_plan, target: t
        )
      }
    }

    it 'is split into different task steps' do
      tasks = DistributeTasks.call(task_plan).outputs.tasks
      tasks.each do |task|
        expect(task.taskings.length).to eq 1
        task_steps = task.task_steps

        expect(task_steps.count).to eq task_step_gold_data.count
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
        end
      end
    end

  end

end

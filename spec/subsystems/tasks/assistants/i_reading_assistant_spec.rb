require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::IReadingAssistant, type: :assistant,
                                                     speed: :slow,
                                                     vcr: VCR_OPTS do

  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant')
  }

  let!(:chapter) {
    FactoryGirl.create :content_chapter, title: "Forces and Newton's Laws of Motion"
  }

  let!(:ecosystem) {
    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(chapter.book.ecosystem)
    ::Content::Ecosystem.new(strategy: ecosystem_strategy)
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
                             book_location: [8, 1]}] },
        { klass: Tasks::Models::TaskedReading,
          title: "Force",
          related_content: [{title: "Force",
                             book_location: [8, 2]}] }
      ]
    }

    let!(:spaced_practice_step_gold_data) {
      [
        { klass: Tasks::Models::TaskedExercise,
          title: nil,
          related_content: [{title: "Force",
                            book_location: [8, 2]}] },
        { klass: Tasks::Models::TaskedExercise,
          title: nil,
          related_content: [{title: "Force",
                             book_location: [8, 2]}] },
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

    let!(:cnx_pages) { cnx_page_hashes.collect do |hash|
      OpenStax::Cnx::V1::Page.new(hash: hash)
    end }

    let!(:pages)     { cnx_pages.collect.with_index do |cnx_page, ii|
      Content::Routines::ImportPage.call(
        cnx_page:  cnx_page,
        chapter: chapter,
        book_location: [8, ii+1]
      ).outputs.page.reload
    end }

    let!(:pools) { Content::Routines::PopulateExercisePools[book: chapter.book] }

    let!(:task_plan) {
      FactoryGirl.build(
        :tasks_task_plan,
        assistant: assistant,
        content_ecosystem_id: ecosystem.id,
        settings: { 'page_ids' => pages.collect{ |page| page.id.to_s } },
        num_tasking_plans: 0
      )
    }

    let!(:course) {
      task_plan.owner.tap do |course|
        AddEcosystemToCourse[course: course, ecosystem: ecosystem]
      end
    }

    let!(:period) { CreatePeriod[course: course] }

    let!(:num_taskees) { 3 }

    let!(:taskee_profiles) {
      num_taskees.times.collect{ FactoryGirl.create(:user_profile) }
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
          FactoryGirl.build(
            :tasks_tasking_plan,
            task_plan: task_plan,
            target:    taskee
          )
      end

      task_plan.save
      tps
    }

    it 'splits a CNX module into many different steps and assigns them with immediate feedback' do
      allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [[0, 2]]}

      entity_tasks = DistributeTasks.call(task_plan).outputs.entity_tasks
      expect(entity_tasks.length).to eq num_taskees

      entity_tasks.each do |entity_task|
        entity_task.reload.reload
        expect(entity_task.taskings.length).to eq 1

        task = entity_task.task
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
            expect(task_step.tasked.book_location).to eq(page.book_location)
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

      expected_roles = taskee_users.collect{ |tu| Role::GetDefaultUserRole[tu] }
      expect(entity_tasks.collect{|et| et.taskings.first.role}).to eq expected_roles
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
        chapter: chapter,
        book_location: [1, 1]
      ).outputs.page.reload
    }

    let!(:pools) { Content::Routines::PopulateExercisePools[book: page.book] }

    let!(:task_plan) {
      FactoryGirl.build(:tasks_task_plan,
        assistant: assistant,
        content_ecosystem_id: ecosystem.id,
        settings: { 'page_ids' => [page.id.to_s] },
        num_tasking_plans: 0
      )
    }

    let!(:course) {
      task_plan.owner.tap do |course|
        AddEcosystemToCourse[course: course, ecosystem: ecosystem]
      end
    }

    let!(:period) { CreatePeriod[course: course] }

    let!(:num_taskees) { 3 }

    let!(:taskee_profiles) {
      num_taskees.times.collect do
        FactoryGirl.create(:user_profile).tap do |profile|
          strategy = User::Strategies::Direct::User.new(profile)
          user = User::User.new(strategy: strategy)
          AddUserAsPeriodStudent.call(user: user, period: period)
        end
      end
    }

    let!(:tasking_plans) {
      tps = taskee_profiles.collect do |taskee|
        task_plan.tasking_plans << FactoryGirl.build(
          :tasks_tasking_plan, task_plan: task_plan, target: taskee
        )
      end

      task_plan.save!
      tps
    }

    it 'is split into different task steps with immediate feedback' do
      allow(Tasks::Assistants::IReadingAssistant).to receive(:k_ago_map) { [[0, 2]]}
      allow(Tasks::Assistants::IReadingAssistant).to receive(:num_personalized_exercises) { 0 }

      entity_tasks = DistributeTasks.call(task_plan).outputs.entity_tasks
      entity_tasks.each do |entity_task|
        entity_task.reload.reload
        expect(entity_task.taskings.length).to eq 1
        expect(entity_task.task.feedback_at).to be <= Time.now

        task_steps = entity_task.task.task_steps

        expect(task_steps.count).to eq task_step_gold_data.count
        task_steps.each_with_index do |task_step, ii|
          expect(task_step.tasked.class).to eq(task_step_gold_data[ii][:klass])
          expect(task_step.tasked.title).to eq(task_step_gold_data[ii][:title])
        end
      end
    end

  end

end

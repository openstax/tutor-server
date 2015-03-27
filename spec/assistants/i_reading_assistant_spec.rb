require 'rails_helper'
require 'vcr_helper'

RSpec.describe IReadingAssistant, :type => :assistant, :vcr => VCR_OPTS do

  let!(:assistant) { FactoryGirl.create :assistant,
                                        code_class_name: 'IReadingAssistant' }
  let!(:book_part) { FactoryGirl.create :content_book_part }

  # Store version differences in this hash
  cnx_page_infos = HashWithIndifferentAccess.new(
    stable: { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083@4', title: 'Force' },
    latest: { id: '092bbf0d-0729-42ce-87a6-fd96fd87a083', title: 'Force' }
  )

  cnx_page_infos.each do |name, hash|

    context "for the #{name.to_s} version" do
      let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: hash) }
      let!(:page)     { Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                                 book_part: book_part)
                                           .outputs.page }
      let!(:task_plan) {
        FactoryGirl.create :task_plan, assistant: assistant,
                                       settings: { page_ids: [page.id] }
      }
      let!(:taskees) { 3.times.collect{ FactoryGirl.create(:user) } }
      let!(:tasking_plans) { taskees.collect{ |t|
        task_plan.tasking_plans << FactoryGirl.create(
          :tasking_plan, task_plan: task_plan, target: t
        )
      } }

      it 'splits a CNX module into many different steps and assigns them' do
        tasks = DistributeTasks.call(task_plan).outputs.tasks
        expect(tasks.length).to eq 3

        tasks.each do |task|
          expect(task.taskings.length).to eq 1
          task_steps = task.task_steps
          expect(task_steps.length).to eq 8

          task_steps.each_with_index do |task_step, i|
            expect(task_step.tasked.content).not_to include('snap-lab')
            expect(page.content).not_to include(task_step.tasked.content) \
              if task_step.tasked_type == 'TaskedExercise'

            task_steps.except(task_step).each do |other_step|
              expect(task_step.tasked.content).not_to(
                include(other_step.tasked.content)
              )
            end
          end

          expect(task_steps.collect{|ts| ts.tasked_type}).to(
            eq ['TaskedReading',  'TaskedReading',  'TaskedExercise',
                'TaskedReading',  'TaskedExercise', 'TaskedExercise',
                'TaskedExercise', 'TaskedExercise']
          )

          expect(task_steps.collect{|ts| ts.tasked.title}).to(
            eq ["Section Learning Objectives; Defining Force and Dynamics",
                "Mars Probe Explosion",
                nil,
                "Free-body Diagrams and Examples of Forces",
                nil,
                nil,
                nil,
                nil]
          )
        end

        expect(tasks.collect{|t| t.taskings.first.taskee}).to eq taskees
        expect(tasks.collect{|t| t.taskings.first.user}).to eq taskees
      end
    end
  end

  context "\"Newton's First Law of Motion: Inertia\"" do
    let!(:cnx_page_hash) { { 'id' => '61445f78-00e2-45ae-8e2c-461b17d9b4fd',
                             'title' => "Newton's First Law of Motion: Inertia" } }
    let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }
    let!(:page) { Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                           book_part: book_part)
                                     .outputs.page }
    let!(:task_plan) {
      FactoryGirl.create :task_plan, assistant: assistant,
                                     settings: { page_ids: [page.id] }
    }
    let!(:taskees) { 3.times.collect{ FactoryGirl.create(:user) } }
    let!(:tasking_plans) { taskees.collect{ |t|
      task_plan.tasking_plans << FactoryGirl.create(
        :tasking_plan, task_plan: task_plan, target: t
      )
    } }

    it 'is split into different task steps' do
      tasks = DistributeTasks.call(task_plan).outputs.tasks
      tasks.each do |task|
        expect(task.taskings.length).to eq 1
        task_steps = task.task_steps
        expect(task_steps.length).to eq 10
        expect(task_steps.collect { |ts| ts.tasked_type }).to eq(
          ['TaskedReading', 'TaskedVideo', 'TaskedExercise',
           'TaskedReading', 'TaskedExercise',
           'TaskedReading', 'TaskedExercise', 'TaskedExercise',
           'TaskedExercise', 'TaskedExercise']
        )
      end
    end
  end

end

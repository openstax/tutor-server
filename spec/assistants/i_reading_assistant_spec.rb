require 'rails_helper'

RSpec.describe IReadingAssistant, :type => :assistant do
  # The module specified here should ideally contain:
  # - Absolute URL's
  # - Relative URL's
  # - Topic (LO)-tagged sections and problems
  fixture_file = 'spec/fixtures/m50577/index.cnxml.html'

  let!(:resource)  { FactoryGirl.create(
    :resource, url: 'http://dum.my/contents/m50577',
               cached_content: open(fixture_file) { |f| f.read }
  ) }
  let!(:page) { FactoryGirl.create :page, resource: resource }
  let!(:task_plan) { FactoryGirl.create :task_plan,
                                        settings: { page_id: Page.last.id } }
  let!(:taskees) { 3.times.collect{ FactoryGirl.create :user } }
  let!(:data) { {} }

  it 'splits a CNX module into many different steps and assigns them' do
    tasks = IReadingAssistant.distribute_tasks(task_plan: task_plan,
                                               taskees: taskees)
    expect(tasks.length).to eq 3

    tasks.each do |task|
      expect(task.taskings.length).to eq 1
      expect(task.task_steps.length).to eq 12

      expect(task.task_steps.collect{|ts| ts.tasked_type}).to(
        eq ['TaskedReading', 'TaskedExercise', 'TaskedReading',
            'TaskedReading', 'TaskedExercise', 'TaskedExercise',
            'TaskedExercise', 'TaskedReading', 'TaskedExercise',
            'TaskedExercise', 'TaskedExercise', 'TaskedExercise']
      )

      expect(task.task_steps.collect{|ts| ts.title}).to(
        eq ['Defining motion',
            'Looking at motion from two frames of reference',
            'Displacement ',
            'Distance',
            'Calculating distance and displacement',
            'PRACTICE PROBLEMS PLACEHOLDER',
            'EXTRA-PRACTICE/HOMEWORK PLACEHOLDER',
            'Vectors and Scalars',
            'The Walking Man',
            'Introduction to vectors and scalars',
            'FORMATIVE ASSESSMENT PLACEHOLDER',
            'Galilean and Newtonian Relativity']
      )
    end

    expect(tasks.collect{|t| t.taskings.first.taskee}).to eq taskees
    expect(tasks.collect{|t| t.taskings.first.user}).to eq taskees
  end
end

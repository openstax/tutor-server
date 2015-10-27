require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::ExtraAssignmentAssistant, type: :assistant, vcr: VCR_OPTS do
  let!(:assistant) {
    FactoryGirl.create(
      :tasks_assistant,
      code_class_name: 'Tasks::Assistants::ExtraAssignmentAssistant')
  }

  let!(:course) { Entity::Course.create }
  let!(:period) { CreatePeriod[course: course] }

  let!(:ecosystem) {
    es = nil
    VCR.use_cassette('Tasks_Assistants_ExtraAssignmentAssistant/with_book', VCR_OPTS) do
      es = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    es
  }

  let!(:task_plan) {
    snap_lab_ids = []
    ecosystem.pages.each do |page|
      if page.snap_labs.present?
        snap_lab_ids << page.snap_labs.first[:id]
      end
    end
    FactoryGirl.build(:tasks_task_plan,
                      assistant: assistant,
                      settings: { snap_lab_ids: snap_lab_ids },
                      owner: course,
                      num_tasking_plans: 0)
  }

  let!(:num_taskees) { 3 }

  let!(:students) {
    num_taskees.times.collect do
      user = FactoryGirl.create(:user)
      AddUserAsPeriodStudent.call(user: user, period: period).outputs.student
    end
  }

  let!(:tasking_plans) {
    FactoryGirl.build(:tasks_tasking_plan,
                      task_plan: task_plan,
                      target: course)
  }

  it 'assigns tasked readings and exercises to students' do
    tasks = DistributeTasks.call(task_plan).outputs.entity_tasks.collect(&:task)
    expect(tasks.length).to eq(num_taskees)
    tasks.each do |task|
      # We added 2 snap lab notes:
      # https://staging-tutor.cnx.org/contents/0e58aa87-2e09-40a7-8bf3-269b2fa16509@9/Acceleration
      # and
      # https://staging-tutor.cnx.org/contents/548a8717-71e1-4d65-80f0-7b8c6ed4b4c0@3/Newtons-Second-Law-of-Motion
      #
      # There is one reading and one exercise for each snap lab note, so in total there are 4 task steps
      expect(task.task_steps.length).to eq(4)
      taskeds = task.task_steps.collect(&:tasked)

      expect(taskeds.collect(&:class)).to eq([
        Tasks::Models::TaskedReading,
        Tasks::Models::TaskedExercise,
        Tasks::Models::TaskedReading,
        Tasks::Models::TaskedExercise
      ])

      content = taskeds.collect(&:content)
      expect(content[0]).to include(
        'if the acceleration of a moving bicycle is constant')
      expect(content[1]).to include(
        'If you graph the average velocity (x-axis) vs. the elapsed time (y-axis)')
      expect(content[2]).to include(
        'What do bathroom scales measure?')
      expect(content[3]).to include(
        'While standing on a bathroom scale,')
    end
  end
end

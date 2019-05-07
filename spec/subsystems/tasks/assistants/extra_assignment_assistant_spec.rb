require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::ExtraAssignmentAssistant, type: :assistant,
                                                            vcr: VCR_OPTS,
                                                            speed: :medium do

  let(:fixture_path)      { 'spec/fixtures/content/sample_tutor_manifest.yml' }
  let(:manifest_contents) { File.open(fixture_path) { |file| file.read } }
  let(:num_taskees)       { 3 }

  let(:assistant)        do
    FactoryBot.create(
      :tasks_assistant,
      code_class_name: 'Tasks::Assistants::ExtraAssignmentAssistant')
  end

  let(:course)           { FactoryBot.create :course_profile_course }
  let(:period)           { FactoryBot.create :course_membership_period, course: course }

  let(:ecosystem)        do
    VCR.use_cassette('Tasks_Assistants_ExtraAssignmentAssistant/with_book', VCR_OPTS) do
      ImportEcosystemManifest[manifest: manifest_contents]
    end
  end

  let(:task_plan)        do
    snap_lab_ids = []
    ecosystem.pages.each do |page|
      snap_lab_ids << "#{page.id}:#{page.snap_labs.first[:id]}" if page.snap_labs.present?
    end
    FactoryBot.create(:tasks_task_plan,
                       assistant: assistant,
                       ecosystem: ecosystem.to_model,
                       settings: { snap_lab_ids: snap_lab_ids },
                       owner: course)
  end

  let!(:students)         do
    num_taskees.times.map do
      user = FactoryBot.create(:user)
      AddUserAsPeriodStudent.call(user: user, period: period).outputs.student
    end
  end

  context 'with no teacher_students' do
    it 'assigns tasked readings and exercises to students' do
      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      expect(tasks.length).to eq(num_taskees)
      tasks.each do |task|
        # We added 2 snap lab notes:
        # https://staging-tutor.cnx.org/contents/0e58aa87-2e09-40a7-8bf3-269b2fa16509@9/Acceleration
        # and
        # https://staging-tutor.cnx.org/contents/548a8717-71e1-4d65-80f0-7b8c6ed4b4c0@3/Newtons-Second-Law-of-Motion
        #
        # There is one reading and one exercise for each snap lab note,
        # so in total there are 4 task steps
        expect(task.task_steps.length).to eq(4)
        taskeds = task.task_steps.map(&:tasked)

        expect(taskeds.map(&:class)).to eq([
          Tasks::Models::TaskedReading,
          Tasks::Models::TaskedExercise,
          Tasks::Models::TaskedReading,
          Tasks::Models::TaskedExercise
        ])

        content = taskeds.map(&:content)
        expect(content[0]).to include(
          'if the acceleration of a moving bicycle is constant'
        )
        expect(content[1]).to include(
          'If you graph the average velocity (x-axis) vs. the elapsed time (y-axis)'
        )
        expect(content[2]).to include(
          'What do bathroom scales measure?'
        )
        expect(content[3]).to include(
          'While standing on a bathroom scale,'
        )
      end
    end
  end

  context 'with a teacher_student' do
    let!(:teacher_student) { FactoryBot.create :course_membership_teacher_student, period: period }

    it 'assigns tasked readings and exercises to students and the teacher_student' do
      tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
      expect(tasks.length).to eq(num_taskees + 1)
      tasks.each do |task|
        # We added 2 snap lab notes:
        # https://staging-tutor.cnx.org/contents/0e58aa87-2e09-40a7-8bf3-269b2fa16509@9/Acceleration
        # and
        # https://staging-tutor.cnx.org/contents/548a8717-71e1-4d65-80f0-7b8c6ed4b4c0@3/Newtons-Second-Law-of-Motion
        #
        # There is one reading and one exercise for each snap lab note,
        # so in total there are 4 task steps
        expect(task.task_steps.length).to eq(4)
        taskeds = task.task_steps.map(&:tasked)

        expect(taskeds.map(&:class)).to eq([
          Tasks::Models::TaskedReading,
          Tasks::Models::TaskedExercise,
          Tasks::Models::TaskedReading,
          Tasks::Models::TaskedExercise
        ])

        content = taskeds.map(&:content)
        expect(content[0]).to include(
          'if the acceleration of a moving bicycle is constant'
        )
        expect(content[1]).to include(
          'If you graph the average velocity (x-axis) vs. the elapsed time (y-axis)'
        )
        expect(content[2]).to include(
          'What do bathroom scales measure?'
        )
        expect(content[3]).to include(
          'While standing on a bathroom scale,'
        )
      end
    end
  end
end

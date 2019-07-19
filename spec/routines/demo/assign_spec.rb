require 'rails_helper'
require 'vcr_helper'

RSpec.describe Demo::Assign, type: :routine do
  let(:config_base_dir)   { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:user_config)       do
    {}.tap do |config|
      hash = YAML.load_file File.join(config_base_dir, 'users', 'review', 'apush.yml')
      config[:users] = Api::V1::Demo::Users::Representer.new(hash).to_hash.deep_symbolize_keys
    end
  end
  let(:import_config)     do
    {}.tap do |config|
      hash = YAML.load_file File.join(config_base_dir, 'import', 'review', 'apush.yml')
      config[:import] = Api::V1::Demo::Import::Representer.new(hash).to_hash.deep_symbolize_keys
    end
  end
  let(:course_config)     do
    {}.tap do |config|
      hash = YAML.load_file File.join(config_base_dir, 'course', 'review', 'apush.yml')
      config[:course] = Api::V1::Demo::Course::Representer.new(hash).to_hash.deep_symbolize_keys
    end
  end
  let(:assign_config)     do
    {}.tap do |config|
      hash = YAML.load_file File.join(config_base_dir, 'assign', 'review', 'apush.yml')
      config[:assign] = Api::V1::Demo::Assign::Representer.new(hash).to_hash.deep_symbolize_keys
    end
  end
  let(:result)            { described_class.call assign_config }

  let!(:course)           do
    Demo::Users.call user_config
    VCR.use_cassette('Demo_Import/imports_the_demo_book', VCR_OPTS) do
      Demo::Import.call import_config
    end
    Demo::Course.call(course_config).outputs.course
  end

  it 'creates demo assignments for the demo students' do
    task_plans = nil
    expect do
      expect(result.errors).to be_empty
      task_plans = result.outputs.task_plans
    end.to  change { Tasks::Models::TaskPlan.count }.by(4)
       .and change { Tasks::Models::Task.count }.by(24)

    task_plans.each do |task_plan|
      matches = /(Read|HW) Chapter 1 (Intro and )?Sections \d and \d/.match task_plan.title
      expect(matches).not_to be_nil
      expect(task_plan.type).to eq matches[1] == 'Read' ? 'reading' : 'homework'
      expect(task_plan.owner).to eq course
      expect(task_plan.ecosystem).to eq course.ecosystems.first
      expect(task_plan.assistant).not_to be_blank
      settings = task_plan.settings
      expect(settings['page_ids'].size).to eq matches[2].blank? ? 2 : 3
      if task_plan.type == 'homework'
        expect(settings['exercise_ids'].size).to eq 3
        expect(settings['exercises_count_dynamic']).to eq 3
      end
      expect(task_plan.is_preview).to eq false

      expect(task_plan.tasking_plans.size).to eq 2
      task_plan.tasking_plans.each do |tasking_plan|
        expect(tasking_plan.target).to be_in course.periods
        expect(tasking_plan.opens_at).to be_within(0.5.week).of(
          DateTime.parse('2019-07-18 12:01:00 -0500')
        )
        expect(tasking_plan.due_at).to be_within(4.5.days).of(
          DateTime.parse('2019-07-28 19:00:00 -0500')
        )
        expect(tasking_plan.time_zone).to eq course.time_zone
      end

      tasks = task_plan.tasks
      expect(tasks.size).to eq 6
      tasks.each do |task|
        expect(task.taskings.size).to eq 1
        expect(task.taskings.first.role.username).to match /reviewstudent\d/

        expect(task.task_type).to eq task_plan.type
        expect(task.task_steps.size).to be_in task.homework? ? [ 6 ] : [ 14, 15 ]
      end
    end
  end
end

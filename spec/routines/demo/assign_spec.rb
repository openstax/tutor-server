require 'rails_helper'
require 'vcr_helper'

RSpec.describe Demo::Assign, type: :routine do
  let(:config_base_dir) { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:user_config)     do
    {
      users: Api::V1::Demo::Users::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'users', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:import_config)   do
    {
      import: Api::V1::Demo::Import::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'import', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:course_config)   do
    {
      course: Api::V1::Demo::Course::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'course', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:assign_config)   do
    {
      assign: Api::V1::Demo::Assign::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'assign', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:result)          { described_class.call assign_config }

  let!(:course)         do
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
    end.to  change { Tasks::Models::TaskPlan.count }.by(5)
       .and change { Tasks::Models::Task.count }.by(30)

    task_plans.each do |task_plan|
      title_regex = case task_plan.type
      when 'reading'
        /Read Chapter 1 (Intro and )?Sections \d and \d/
      when 'homework'
        /HW Chapter 1 (Intro and )?Sections \d and \d/
      when 'external'
        /External/
      end

      matches = title_regex.match task_plan.title
      expect(matches).not_to be_nil
      expect(task_plan.course).to eq course
      expect(task_plan.ecosystem).to eq course.ecosystems.first
      expect(task_plan.assistant).not_to be_blank
      expect(task_plan.grading_template).to(be_in course.grading_templates) \
        unless task_plan.type == 'external'
      case task_plan.type
      when 'reading'
        expect(task_plan.core_page_ids.size).to eq matches[1].blank? ? 2 : 3
      when 'homework'
        expect(task_plan.core_page_ids.size).to eq matches[1].blank? ? 2 : 3
        expect(task_plan.settings['exercises'].size).to eq 4
        expect(task_plan.settings['exercises_count_dynamic']).to eq 2
      when 'external'
        expect(task_plan.settings['external_url']).to eq 'https://example.com/External'
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
        expect(tasking_plan.closes_at).to be_within(4.5.days).of(
          DateTime.parse('2019-08-04 19:00:00 -0500')
        )
        expect(tasking_plan.timezone).to eq course.timezone
      end

      expected_num_steps = case task_plan.type
      when 'reading'
        [ 14, 15 ]
      when 'homework'
        [ 6 ]
      when 'external'
        [ 1 ]
      end

      tasks = task_plan.tasks
      expect(tasks.size).to eq 6
      tasks.each do |task|
        expect(task.taskings.size).to eq 1
        expect(task.taskings.first.role.username).to match /reviewstudent\d/

        expect(task.task_type).to eq task_plan.type
        expect(task.task_steps.size).to be_in expected_num_steps
      end
    end
  end
end

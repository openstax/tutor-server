require 'rails_helper'
require 'vcr_helper'

RSpec.describe Demo::Work, type: :routine do
  EXPECTED_COMPLETION  = [ 1, 0.8, 0.6, 0.4, 0.2, 0 ]
  EXPECTED_SCORES      = [ 1, 0.8, 0.5, 0.3, 0  , 0 ]

  let(:config_base_dir)   { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:user_config)       do
    {
      users: Api::V1::Demo::Users::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'users', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:import_config)     do
    {
      import: Api::V1::Demo::Import::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'import', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:course_config)     do
    {
      course: Api::V1::Demo::Course::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'course', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:assign_config)     do
    {
      assign: Api::V1::Demo::Assign::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'assign', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:work_config)       do
    {
      work: Api::V1::Demo::Work::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'work', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:result)            { described_class.call work_config }

  let!(:course)           do
    Demo::Users.call user_config
    ecosystem = FactoryBot.create :mini_ecosystem
    FactoryBot.create :catalog_offering, ecosystem: ecosystem, title: 'AP US History'
    Demo::Course.call(course_config).outputs.course
  end
  let!(:task_plans)       { Demo::Assign.call(assign_config).outputs.task_plans }

  it 'works demo assignments' do
    expect(result.errors).to be_empty

    expect(task_plans.size).to eq 5
    task_plans.each do |task_plan|
      tasks = task_plan.tasks
      expect(tasks.size).to eq 6
      tasks.each do |task|
        if task.title.include? 'External'
          student_index = task.taskings.first.role.username.reverse.to_i - 1
          expect(task.completion).to eq student_index < 3 ? 1.0 : 0.0
          expect(task.score).to be_nil
        elsif task.title.include? 'Intro'
          student_index = task.taskings.first.role.username.reverse.to_i - 1
          expected_completion = EXPECTED_COMPLETION[student_index]
          expect(task.completion).to be_within(1.0/task.steps_count).of(expected_completion)

          expected_score = EXPECTED_SCORES[student_index]
          # Only 100% accurate if the expected score is 0
          # Any other value depends on chance
          # Even 1.0 depends on having no WRQs
          if expected_score == 0.0
            if expected_completion == 0.0
              expect(task.score).to eq(0.0)
            elsif expected_completion == 1.0
              expect(task.score).to eq(task.completion_weight)
            end
          end
        else
          expect(task.completion).to eq 0
          expect(task.score).to eq 0
        end
      end
    end
  end
end

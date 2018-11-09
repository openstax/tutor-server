require 'rails_helper'

RSpec.describe Tasks::IsReady, type: :routine do

  before(:all) do
    @ready_task_1 = FactoryBot.create(
      :tasks_tasked_placeholder, placeholder_type: :exercise_type
    ).task_step.tap do |ts|
      ts.update_attribute :group_type, :core_group
    end.task.tap do |task|
      task.update_attribute :pes_are_assigned, true
    end
    @ready_task_2 = FactoryBot.create(
      :tasks_tasked_placeholder, placeholder_type: :exercise_type
    ).task_step.tap do |ts|
      ts.update_attribute :group_type, :spaced_practice_group
    end.task.tap { |task| task.update_step_counts.save! }
    @biglearn_task_1 = FactoryBot.create(
      :tasks_tasked_placeholder, placeholder_type: :exercise_type
    ).task_step.tap do |ts|
      ts.update_attribute :group_type, :personalized_group
    end.task
    @biglearn_task_2 = FactoryBot.create(
      :tasks_tasked_placeholder, placeholder_type: :exercise_type
    ).task_step.tap do |ts|
      ts.update_attribute :group_type, :core_group
    end.task

    @requests = [@biglearn_task_1, @biglearn_task_2].map do |task|
      {
        task: task,
        max_num_exercises: 1,
        inline_max_attempts: 1,
        inline_sleep_interval: 0,
        enable_warnings: false
      }
    end

    @responses = {}
    @requests.each do |request|
      @responses[request] = { accepted: request[:task] == @biglearn_task_1 }
    end

    @ready_tasks = [ @ready_task_1, @ready_task_2, @biglearn_task_1 ]
    @tasks = @ready_tasks + [ @biglearn_task_2 ]
  end

  before do
    expect(OpenStax::Biglearn::Api).to(
      receive(:fetch_assignment_pes).with(@requests).and_return(@responses)
    )
  end

  it 'returns a set with the ids of all the tasks that are ready' do
    expect(described_class[tasks: @tasks]).to eq Set.new(@ready_tasks.map(&:id))
  end
end

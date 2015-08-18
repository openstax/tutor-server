require 'rails_helper'

RSpec.describe Tasks::Assistants::EventAssistant, type: :assistant do
  let(:assistant) do
    FactoryGirl.create(:tasks_assistant,
                       code_class_name: 'Tasks::Assistants::EventAssistant')
  end

  let(:course) { Entity::Course.create }
  let(:period) { CourseMembership::Models::Period.last }

  before do
    CreatePeriod[course: course]

    3.times do
      user = FactoryGirl.create(:user_profile).entity_user
      AddUserAsPeriodStudent[user: user, period: period]
    end
  end

  it 'assigns tasked events to students' do
    task_plan = FactoryGirl.build(:tasks_task_plan,
                                  assistant: assistant,
                                  owner: course,
                                  num_tasking_plans: 0)
    FactoryGirl.create(:tasks_tasking_plan, task_plan: task_plan, target: course)

    tasks = DistributeTasks.call(task_plan).outputs.entity_tasks.flat_map(&:task)

    expect(tasks.length).to eq 3
    expect(tasks.flat_map(&:task_type).uniq).to eq(['event'])
  end

  it 'raises an error if taskees are not students' do
    task_plan = FactoryGirl.build(:tasks_task_plan,
                                  assistant: assistant,
                                  owner: course,
                                  num_tasking_plans: 0)

    FactoryGirl.create(:tasks_tasking_plan, task_plan: task_plan, target: course)

    # If the target of a tasking plan is an entity user,
    # taskee will be the user's default role,
    # which is not a student role
    FactoryGirl.create(:tasks_tasking_plan,
                       task_plan: task_plan,
                       target: UserProfile::Models::Profile.first)

    expect {
      DistributeTasks.call(task_plan)
    }.to raise_error(StandardError, 'Event assignment taskees must all be students')
  end
end

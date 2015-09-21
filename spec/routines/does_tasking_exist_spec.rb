require 'rails_helper'

RSpec.describe DoesTaskingExist, type: :routine do
  let(:nontaskee) { FactoryGirl.create(:user_profile_profile) }
  let(:taskee)    { FactoryGirl.create(:user_profile_profile) }
  let(:tasked)    { FactoryGirl.create(:tasks_tasked_exercise) }
  let!(:tasking)  { FactoryGirl.create(:tasks_tasking,
                                       role: Role::GetDefaultUserRole[taskee.user],
                                       task: tasked.task_step.task.entity_task) }

  it "returns true for a tasked and the taskee" do
    expect(DoesTaskingExist[task_component: tasked, user: taskee.user]).to be_truthy
  end

  it "returns true for a task step and the taskee" do
    expect(DoesTaskingExist[task_component: tasked.task_step, user: taskee.user]).to be_truthy
  end

  it "returns true for a task and the taskee" do
    expect(DoesTaskingExist[task_component: tasked.task_step.task, user: taskee.user]).to be_truthy
  end

  it "returns false for a tasked and the nontaskee" do
    expect(DoesTaskingExist[task_component: tasked, user: nontaskee.user]).to be_falsy
  end

  it "returns false for a task step and the nontaskee" do
    expect(DoesTaskingExist[task_component: tasked.task_step, user: nontaskee.user]).to be_falsy
  end

  it "returns false for a task and the nontaskee" do
    expect(DoesTaskingExist[task_component: tasked.task_step.task, user: nontaskee.user]).to be_falsy
  end

end

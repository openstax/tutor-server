require 'rails_helper'

RSpec.describe Domain::DoesTaskingExist, :type => :routine do
  let(:nontaskee) { FactoryGirl.create(:user) }
  let(:taskee)    { FactoryGirl.create(:user) }
  let(:tasked)    { FactoryGirl.create(:tasked_exercise) }
  let!(:tasking)  { FactoryGirl.create(:tasking, taskee: taskee, task: tasked.task_step.task) }

  it "returns true for a tasked and the taskee" do
    expect(Domain::DoesTaskingExist[task_component: tasked, user: taskee]).to be_truthy
  end

  it "returns true for a task step and the taskee" do
    expect(Domain::DoesTaskingExist[task_component: tasked.task_step, user: taskee]).to be_truthy
  end

  it "returns true for a task and the taskee" do
    expect(Domain::DoesTaskingExist[task_component: tasked.task_step.task, user: taskee]).to be_truthy
  end

  it "returns false for a tasked and the nontaskee" do
    expect(Domain::DoesTaskingExist[task_component: tasked, user: nontaskee]).to be_falsy
  end

  it "returns false for a task step and the nontaskee" do
    expect(Domain::DoesTaskingExist[task_component: tasked.task_step, user: nontaskee]).to be_falsy
  end

  it "returns false for a task and the nontaskee" do
    expect(Domain::DoesTaskingExist[task_component: tasked.task_step.task, user: nontaskee]).to be_falsy
  end

  it "returns true for a task tasked in the Tasks subsystem" do
    role = Role::CreateUserRole[taskee]
    Tasks::CreateTasking.call(task: tasked.task_step.task, role: role)

    expect(Domain::DoesTaskingExist[task_component: tasked, user: taskee]).to be_truthy
  end

end

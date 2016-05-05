require 'rails_helper'

RSpec.describe Tasks::GetRedirectUrl, type: :routine do
  let!(:course) { CreateCourse[name: 'Test Task Redirection'] }
  let!(:period) { CreatePeriod[course: course, name: 'Period I'] }

  let!(:task_plan) { FactoryGirl.create(:tasks_task_plan, owner: course) }
  let!(:task_plan_gid) { task_plan.to_global_id.to_s }

  let!(:task) { FactoryGirl.create(:tasks_task, task_plan: task_plan) }

  let!(:teacher) { FactoryGirl.create(:user) }
  let!(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  let!(:student) { FactoryGirl.create(:user) }
  let!(:student_role) { AddUserAsPeriodStudent[period: period, user: student] }

  let!(:user) { FactoryGirl.create(:user) }

  let!(:tasking) { FactoryGirl.create(:tasks_tasking, role: student_role, task: task.entity_task) }

  it 'returns the edit task plan page for teachers' do
    result = described_class.call(gid: task_plan_gid, user: teacher)
    expect(result.errors).to be_empty
    expect(result.outputs.uri).to eq("/courses/#{course.id}/t/readings/#{task_plan.id}")
  end

  it 'returns the task page for students' do
    result = described_class.call(gid: task_plan_gid, user: student)
    expect(result.errors).to be_empty
    expect(result.outputs.uri).to eq("/courses/#{course.id}/tasks/#{task.entity_task.id}")
  end

  it 'raises SecurityTransgression for users not in the course' do
    expect {
      described_class.call(gid: task_plan_gid, user: user)
    }.to raise_error(SecurityTransgression)
  end

  it 'raises SecurityTransgression for anonymous users' do
    expect {
      described_class.call(gid: task_plan_gid, user: User::User.anonymous)
    }.to raise_error(SecurityTransgression)
  end
end

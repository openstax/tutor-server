require 'rails_helper'

RSpec.describe Tasks::GetRedirectUrl, type: :routine do
  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan) { FactoryBot.create(:tasks_task_plan, owner: course) }
  let(:task_plan_gid) { task_plan.to_global_id.to_s }

  let(:task) { FactoryBot.create(:tasks_task, task_plan: task_plan) }

  let(:student)       { FactoryBot.create(:user) }
  let!(:student_role) { AddUserAsPeriodStudent[period: period, user: student] }

  let(:teacher)       { FactoryBot.create(:user) }
  let!(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  let(:user) { FactoryBot.create(:user) }

  let!(:tasking) { FactoryBot.create(:tasks_tasking, role: student_role, task: task) }

  it 'returns the edit task plan page for teachers' do
    result = described_class.call(gid: task_plan_gid, user: teacher)
    expect(result.errors).to be_empty
    due_at = task_plan.tasking_plans.first.due_at_ntz.strftime('%Y-%m-%d')
    expect(result.outputs.uri).to eq("/course/#{course.id}/t/month/#{due_at}/plan/#{task_plan.id}")
  end

  it 'returns the task page for students' do
    result = described_class.call(gid: task_plan_gid, user: student)
    expect(result.errors).to be_empty
    expect(result.outputs.uri).to eq("/course/#{course.id}/task/#{task.id}")
  end

  it 'returns :authentication_required for anonomouse users' do
    expect(
      described_class.call(gid: task_plan_gid, user: User::User.anonymous)
    ).to have_routine_error(:authentication_required)
  end

  it 'returns :user_not_in_course_with_required_role for users not in the course' do
    expect(
      described_class.call(gid: task_plan_gid, user: user)
    ).to have_routine_error(:user_not_in_course_with_required_role)
  end
end

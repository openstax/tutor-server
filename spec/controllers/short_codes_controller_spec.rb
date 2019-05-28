require 'rails_helper'

RSpec.describe ShortCodesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  let(:absolute_url) { FactoryBot.create(:short_code_short_code, uri: 'https://cnx.org') }
  let(:relative_url) { FactoryBot.create(:short_code_short_code, uri: 'dashboard') }

  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan) { FactoryBot.create(:tasks_task_plan, owner: course) }
  let(:task_plan_gid) { task_plan.to_global_id.to_s }

  let(:task) { FactoryBot.create(:tasks_task, task_plan: task_plan) }

  let(:teacher) { FactoryBot.create(:user) }
  let!(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  let(:student) { FactoryBot.create(:user) }
  let(:student_role) { AddUserAsPeriodStudent[period: period, user: student] }

  let(:tasking) { FactoryBot.create(:tasks_tasking, role: student_role, task: task) }
  let(:tasking_gid) { tasking.to_global_id.to_s }

  let(:task_plan_code) { FactoryBot.create(:short_code_short_code, uri: task_plan_gid) }

  let(:tasking_code) { FactoryBot.create(:short_code_short_code, uri: tasking_gid) }

  let(:task_plan_due_at) { task_plan.tasking_plans.first.due_at_ntz.strftime('%Y-%m-%d') }

  it 'redirects users to sign in before access' do
    get :redirect, params: { short_code: absolute_url.code }
    expect(response).to redirect_to(%r{/accounts/login})
  end

  it 'redirects users to absolute urls' do
    controller.sign_in(teacher)
    get :redirect, params: { short_code: absolute_url.code }
    expect(response).to redirect_to('https://cnx.org')
  end

  it 'redirects users to relative urls' do
    controller.sign_in(student)
    get :redirect, params: { short_code: relative_url.code }
    expect(response).to redirect_to('dashboard')
  end

  it 'redirects teachers to edit task plan page' do
    controller.sign_in(teacher)
    get :redirect, params: { short_code: task_plan_code.code }

    expect(response).to redirect_to("/course/#{course.id}/t/month/#{task_plan_due_at}/plan/#{task_plan.id}")
  end

  it 'redirects students to task page' do
    controller.sign_in(student)
    expected_url = "/course/#{course.id}/task/#{tasking.task.id}"

    get :redirect, params: { short_code: task_plan_code.code }
    expect(response).to redirect_to(expected_url)
  end

  it 'raises ShortCodeNotFound for short code not found' do
    controller.sign_in(user)
    expect do
      get :redirect, params: { short_code: 'somethingrandom' }
    end.to raise_error(ShortCodeNotFound)
  end

  it 'gives a 403 for users who cannot see the task plan' do
    controller.sign_in(user)
    get :redirect, params: { short_code: task_plan_code.code }
    expect(response).to have_http_status(:forbidden)
  end

  it 'returns 404 for short code with a non task plan GID' do
    controller.sign_in(student)

    expect do
      get :redirect, params: { short_code: tasking_code.code }
    end.to raise_error(StandardError)
  end
end

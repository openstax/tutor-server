require 'rails_helper'

RSpec.describe ShortCodesController, type: :request do
  let(:user) { FactoryBot.create(:user_profile) }

  let(:absolute_url) { FactoryBot.create(:short_code_short_code, uri: 'https://openstax.org/apps/archive/20201222.172624') }
  let(:relative_url) { FactoryBot.create(:short_code_short_code, uri: '/dashboard') }

  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan) { FactoryBot.create(:tasks_task_plan, course: course) }
  let(:task_plan_gid) { task_plan.to_global_id.to_s }

  let(:task) { FactoryBot.create(:tasks_task, task_plan: task_plan) }

  let(:teacher) { FactoryBot.create(:user_profile) }
  let!(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  let(:student) { FactoryBot.create(:user_profile) }
  let(:student_role) { AddUserAsPeriodStudent[period: period, user: student] }

  let(:tasking) { FactoryBot.create(:tasks_tasking, role: student_role, task: task) }
  let(:tasking_gid) { tasking.to_global_id.to_s }

  let(:task_plan_code) { FactoryBot.create(:short_code_short_code, uri: task_plan_gid) }

  let(:tasking_code) { FactoryBot.create(:short_code_short_code, uri: tasking_gid) }

  let(:task_plan_due_at) { task_plan.tasking_plans.first.due_at_ntz.strftime('%Y-%m-%d') }

  it 'redirects users to sign in before access' do
    get short_code_url(absolute_url.code)
    expect(response).to redirect_to(controller.send(:openstax_accounts_login_path))
  end

  it 'redirects users to absolute urls' do
    sign_in! teacher
    get short_code_url(absolute_url.code)
    expect(response).to redirect_to('https://openstax.org/apps/archive/20201222.172624')
  end

  it 'redirects users to relative urls' do
    sign_in! student
    get short_code_url(relative_url.code)
    expect(response).to redirect_to(dashboard_path)
  end

  it 'redirects teachers to edit task plan page' do
    sign_in! teacher
    get short_code_url(task_plan_code.code)

    expect(response).to redirect_to(
      "#{course_dashboard_path(course.id)}/assignment/review/#{task_plan.id}"
    )
  end

  it 'redirects students to task page' do
    sign_in! student
    expected_url = "#{course_dashboard_path(course.id)}/task/#{tasking.task.id}"

    get short_code_url(task_plan_code.code)
    expect(response).to redirect_to(expected_url)
  end

  it 'raises ShortCodeNotFound for short code not found' do
    sign_in! user
    expect do
      get short_code_url('somethingrandom')
    end.to raise_error(ShortCodeNotFound)
  end

  it 'gives a 403 for users who cannot see the task plan' do
    sign_in! user
    get short_code_url(task_plan_code.code)
    expect(response).to have_http_status(:forbidden)
  end

  it 'returns 404 for short code with a non task plan GID' do
    sign_in! student

    expect do
      get short_code_url(tasking_code.code)
    end.to raise_error(StandardError)
  end
end

require 'rails_helper'

RSpec.describe ShortCodesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  let(:absolute_url) { FactoryGirl.create(:short_code_short_code,
                                          uri: 'https://cnx.org') }
  let(:relative_url) { FactoryGirl.create(:short_code_short_code,
                                          uri: 'dashboard') }

  let(:course) { FactoryGirl.create :course_profile_course }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }

  let(:task_plan) { FactoryGirl.create(:tasks_task_plan, owner: course) }
  let(:task_plan_gid) { task_plan.to_global_id.to_s }

  let(:task) { FactoryGirl.create(:tasks_task, task_plan: task_plan) }

  let(:teacher) { FactoryGirl.create(:user) }
  let!(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  let(:student) { FactoryGirl.create(:user) }
  let(:student_role) { AddUserAsPeriodStudent[period: period, user: student] }

  let(:tasking) { FactoryGirl.create(:tasks_tasking, role: student_role, task: task) }
  let(:tasking_gid) { tasking.to_global_id.to_s }

  let(:task_plan_code) { FactoryGirl.create(:short_code_short_code,
                                            uri: task_plan_gid) }

  let(:tasking_code) { FactoryGirl.create(:short_code_short_code,
                                          uri: tasking_gid) }

  let(:task_plan_due_at) { task_plan.tasking_plans.first.due_at_ntz.strftime('%Y-%m-%d') }

  it 'redirects users to sign in before access' do
    get :redirect, short_code: absolute_url.code
    expect(response).to redirect_to(%r{/accounts/login})
  end

  it 'redirects users to absolute urls' do
    controller.sign_in(teacher)
    get :redirect, short_code: absolute_url.code
    expect(response).to redirect_to('https://cnx.org')
  end

  it 'redirects users to relative urls' do
    controller.sign_in(student)
    get :redirect, short_code: relative_url.code
    expect(response).to redirect_to('dashboard')
  end

  it 'redirects teachers to edit task plan page' do
    controller.sign_in(teacher)
    get :redirect, short_code: task_plan_code.code

    expect(response).to redirect_to("/course/#{course.id}/t/month/#{task_plan_due_at}/plan/#{task_plan.id}")
  end

  it 'redirects students to task page' do
    controller.sign_in(student)
    expected_url = "/course/#{course.id}/task/#{tasking.task.id}"

    get :redirect, short_code: task_plan_code.code
    expect(response).to redirect_to(expected_url)
  end

  it 'raises ShortCodeNotFound for short code not found' do
    controller.sign_in(user)
    expect {
      get :redirect, short_code: 'somethingrandom'
    }.to raise_error(ShortCodeNotFound)
  end

  it 'raises SecurityTransgression for users who cannot see the task plan' do
    controller.sign_in(user)

    expect {
      get :redirect, short_code: task_plan_code.code
    }.to raise_error(SecurityTransgression)
  end

  it 'returns 404 for short code with a non task plan GID' do
    controller.sign_in(student)

    expect {
      get :redirect, short_code: tasking_code.code
    }.to raise_error(StandardError)
  end
end

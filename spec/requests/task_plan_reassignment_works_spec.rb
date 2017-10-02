require 'rails_helper'

RSpec.describe 'Task plan reassignment works', type: :request, api: true, version: :v1 do
  let(:course) { FactoryGirl.create :course_profile_course }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }

  let(:student_user) { FactoryGirl.create(:user) }
  let(:teacher_user) { FactoryGirl.create(:user) }

  let(:teacher_role)    { AddUserAsCourseTeacher[user: teacher_user, course: course] }
  let!(:teacher)        { teacher_role.teacher }
  let(:application)     { FactoryGirl.create :doorkeeper_application }

  let(:student_token)   do
    FactoryGirl.create :doorkeeper_access_token,
                       application: application,
                       resource_owner_id: student_user.id
  end
  let(:teacher_token)   do
    FactoryGirl.create :doorkeeper_access_token,
                       application: application,
                       resource_owner_id: teacher_user.id
  end

  let(:task_plan_1) do
    FactoryGirl.build(:tasks_task_plan, owner: course).tap do |task_plan|
      task_plan.tasking_plans.first.target = period.to_model
      task_plan.save!
    end
  end

  scenario 'new students added after assignments published get those assignments' do
    # Publish the assignment, and no one around to get it...
    DistributeTasks.call(task_plan: task_plan_1)
    # TeacherStudent role still gets it
    expect(Tasks::Models::Tasking.count).to eq 1

    # The student signs up...
    api_post('/api/enrollment', student_token,
             raw_post_data: { enrollment_code: period.enrollment_code })
    enrollment_change_id = response.body_as_hash[:id]
    api_put("/api/enrollment/#{enrollment_change_id}/approve", student_token)

    # ... and they have the assignment
    expect(Tasks::Models::Tasking.count).to eq 2
    expect(student_user.to_model.roles.first.taskings.count).to eq 1
  end

  scenario 'undropped student gets assignments published while he was dropped' do
    # The student enrolls...
    api_post('/api/enrollment', student_token,
             raw_post_data: { enrollment_code: period.enrollment_code })
    enrollment_change_id = response.body_as_hash[:id]
    api_put("/api/enrollment/#{enrollment_change_id}/approve", student_token)
    expect(CourseMembership::GetPeriodStudentRoles[periods: period]).not_to be_empty

    # The teacher drops the student...
    student = CourseMembership::Models::Student.first
    api_delete("/api/students/#{student.id}", teacher_token)
    expect(CourseMembership::GetPeriodStudentRoles[periods: period]).to be_empty

    # The teacher publishes an assignment, and no one gets it...
    DistributeTasks.call(task_plan: task_plan_1)
    # TeacherStudent role still gets it
    expect(Tasks::Models::Tasking.count).to eq 1

    # The teacher undrops the student...
    api_put("/api/students/#{student.id}/undrop", teacher_token)

    # ... and the student has the missing task
    expect(Tasks::Models::Tasking.count).to eq 2
    expect(student_user.to_model.roles.first.taskings.count).to eq 1
  end

end

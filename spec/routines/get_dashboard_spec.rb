require 'rails_helper'
require 'vcr_helper'

describe GetDashboard, type: :routine do

  let!(:course)         { CreateCourse[name: 'Physics 101'] }
  let!(:period)         { CreatePeriod[course: course] }

  let!(:student_user)   { FactoryGirl.create(:user) }
  let!(:student_role)   { AddUserAsPeriodStudent.call(user: student_user, period: period)
                                                .outputs.role }

  let!(:teacher_user)   { FactoryGirl.create(:user, first_name: 'Bob',
                                                    last_name: 'Newhart',
                                                    full_name: 'Bob Newhart') }
  let!(:teacher_role)   { AddUserAsCourseTeacher.call(user: teacher_user, course: course)
                                                .outputs.role }

  let!(:reading_task)   { FactoryGirl.create(:tasks_task,
                                             task_type: :reading,
                                             step_types: [:tasks_tasked_reading,
                                                          :tasks_tasked_exercise,
                                                          :tasks_tasked_exercise],
                                             tasked_to: student_role)}

  let!(:homework_task)   { FactoryGirl.create(:tasks_task,
                                              task_type: :reading,
                                              opens_at: 1.day.from_now,
                                              step_types: [:tasks_tasked_exercise,
                                                           :tasks_tasked_exercise,
                                                           :tasks_tasked_exercise],
                                              tasked_to: student_role)}

  let!(:plan) { FactoryGirl.create(:tasks_task_plan, owner: course)}

  it "works for a student" do
    outputs = described_class.call(course: course, role: student_role).outputs

    expect(HashWithIndifferentAccess[outputs]).to include(
      course: {
        id: course.id,
        name: "Physics 101",
        teachers: [
          { id: teacher_role.teacher.id.to_s,
            role_id: teacher_role.id.to_s,
            first_name: 'Bob',
            last_name: 'Newhart' }
        ]
      },
      role: {
        id: student_role.id,
        type: 'student'
      },
      tasks: a_collection_including(
        reading_task # the un-opened homework_task is not included
      )
    )
  end

  it "works for a teacher" do
    outputs = described_class.call(course: course, role: teacher_role).outputs

    expect(HashWithIndifferentAccess[outputs]).to include(
      course: {
        id: course.id,
        name: "Physics 101",
        teachers: [
          { id: teacher_role.teacher.id.to_s,
            role_id: teacher_role.id.to_s,
            first_name: 'Bob',
            last_name: 'Newhart' }
        ]
      },
      role: {
        id: teacher_role.id,
        type: 'teacher'
      },
      tasks: [],
      plans: [
        {
          id: plan.id,
          title: plan.title,
          type: plan.type,
          is_publish_requested: false,
          published_at: nil,
          publish_last_requested_at: nil,
          publish_job_uuid: nil,
          tasking_plans: plan.tasking_plans,
          is_trouble: false
        }
      ]
    )
  end

end

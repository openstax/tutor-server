require 'rails_helper'
require 'vcr_helper'

describe Api::V1::Courses::Dashboard, :type => :routine, :vcr => VCR_OPTS do

  let!(:course)         { CreateCourse[name: 'Physics 101'] }

  let!(:student_user)   { FactoryGirl.create(:user_profile).entity_user }
  let!(:student_role)   { AddUserAsCourseStudent.call(user: student_user,
                                                      course: course)
                                                .outputs.role }

  let!(:teacher_user)   { FactoryGirl.create(:user_profile,
                                             first_name: 'Bob',
                                             last_name: 'Newhart',
                                             full_name: 'Bob Newhart').entity_user }
  let!(:teacher_role)   { AddUserAsCourseTeacher.call(user: teacher_user,
                                                      course: course)
                                                .outputs.role }

  let!(:reading_task)   { FactoryGirl.create(:tasks_task,
                                             task_type: :reading,
                                             step_types: [:tasks_tasked_reading,
                                                          :tasks_tasked_exercise,
                                                          :tasks_tasked_exercise],
                                             tasked_to: student_role)}

  let!(:homework_task)   { FactoryGirl.create(:tasks_task,
                                              task_type: :reading,
                                              step_types: [:tasks_tasked_exercise,
                                                           :tasks_tasked_exercise,
                                                           :tasks_tasked_exercise],
                                              tasked_to: student_role)}

  let!(:plan) { FactoryGirl.create(:tasks_task_plan, owner: course)}

  it "works for a student" do
    outputs = Api::V1::Courses::Dashboard.call(course: course, role: student_role).outputs

    expect(HashWithIndifferentAccess[outputs]).to include(
      course: {
        id: course.id,
        name: "Physics 101",
        teacher_names: ['Bob Newhart']
      },
      role: {
        id: student_role.id,
        type: 'student'
      },
      tasks: a_collection_including(
        reading_task,
        homework_task
      )
    )
  end

  it "works for a teacher" do
    outputs = Api::V1::Courses::Dashboard.call(course: course, role: teacher_role).outputs

    expect(HashWithIndifferentAccess[outputs]).to include(
      course: {
        id: course.id,
        name: "Physics 101",
        teacher_names: ['Bob Newhart']
      },
      role: {
        id: teacher_role.id,
        type: 'teacher'
      },
      tasks: [],
      plans: [plan]
    )
  end

end

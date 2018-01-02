require 'rails_helper'
require 'vcr_helper'

RSpec.describe GetTpDashboard, type: :routine, speed: :slow do

  let(:course)         { FactoryBot.create :course_profile_course, name: 'Physics 101' }
  let(:period)         { FactoryBot.create :course_membership_period, course: course }

  let(:student_user)   { FactoryBot.create(:user) }
  let(:student_role)   { AddUserAsPeriodStudent.call(user: student_user, period: period)
                                               .outputs.role }

  let(:teacher_user)   { FactoryBot.create(:user, first_name: 'Bob',
                                                   last_name: 'Newhart',
                                                   full_name: 'Bob Newhart') }
  let!(:teacher_role)  { AddUserAsCourseTeacher.call(user: teacher_user, course: course)
                                               .outputs.role }

  let!(:hidden_reading_task) do
    FactoryBot.create(:tasks_task,
                       task_type: :reading,
                       step_types: [:tasks_tasked_reading,
                                    :tasks_tasked_exercise,
                                    :tasks_tasked_exercise],
                       tasked_to: student_role).tap do |task|
      task.destroy!
      task.hide.save!
    end
  end

  let!(:deleted_reading_task) do
    FactoryBot.create(:tasks_task,
                       task_type: :reading,
                       step_types: [:tasks_tasked_reading,
                                    :tasks_tasked_exercise,
                                    :tasks_tasked_exercise],
                       tasked_to: student_role).tap do |task|
      task.destroy!
    end
  end

  let!(:reading_task) do
    FactoryBot.create(:tasks_task,
                       task_type: :reading,
                       step_types: [:tasks_tasked_reading,
                                    :tasks_tasked_exercise,
                                    :tasks_tasked_exercise],
                       tasked_to: student_role)
  end

  let!(:homework_task) do
    FactoryBot.create(:tasks_task,
                       task_type: :reading,
                       opens_at: 1.day.from_now,
                       step_types: [:tasks_tasked_exercise,
                                    :tasks_tasked_exercise,
                                    :tasks_tasked_exercise],
                       tasked_to: student_role)
  end

  let!(:plan) { FactoryBot.create(:tasks_task_plan, owner: course) }

  context 'with no time period specified' do
    it "works for a student" do
      outputs = described_class.call(course: course, role: student_role).outputs

      expect(outputs).to match a_hash_including(
        course: {
          id: course.id,
          name: 'Physics 101',
          teachers: [
            { id: teacher_role.teacher.id.to_s,
              role_id: teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart',
              deleted_at: nil }
          ]
        },
        role: {
          id: student_role.id,
          type: 'student'
        },
        tasks: a_collection_including(
          deleted_reading_task, reading_task # the un-opened homework_task is not included
        )
      )
    end

    it "works for a teacher" do
      outputs = described_class.call(course: course, role: teacher_role).outputs

      expect(outputs).to match a_hash_including(
        course: {
          id: course.id,
          name: 'Physics 101',
          teachers: [
            {
              id: teacher_role.teacher.id.to_s,
              role_id: teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart',
              deleted_at: nil
            }
          ]
        },
        role: {
          id: teacher_role.id,
          type: 'teacher'
        },
        tasks: [],
        plans: [
          a_hash_including(
            id: plan.id,
            title: plan.title,
            type: plan.type,
            description: plan.description,
            is_feedback_immediate: plan.is_feedback_immediate,
            is_draft?: plan.is_draft?,
            is_publishing?: plan.is_publishing?,
            is_published?: plan.is_published?,
            first_published_at: plan.first_published_at,
            last_published_at: plan.last_published_at,
            publish_last_requested_at: plan.publish_last_requested_at,
            publish_job_uuid: plan.publish_job_uuid,
            shareable_url: ShortCode::UrlFor[plan],
            tasking_plans: plan.tasking_plans,
            is_trouble: false
          )
        ]
      )
    end
  end

  context 'with a time period specified' do
    let(:start_at_ntz) { DateTimeUtilities.remove_tz(Time.current.yesterday) }
    let(:end_at_ntz)   { DateTimeUtilities.remove_tz(Time.current) }

    it "works for a student" do
      outputs = described_class.call(course: course, role: student_role,
                                     start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz).outputs

      expect(outputs).to match a_hash_including(
        course: {
          id: course.id,
          name: 'Physics 101',
          teachers: [
            { id: teacher_role.teacher.id.to_s,
              role_id: teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart',
              deleted_at: nil }
          ]
        },
        role: {
          id: student_role.id,
          type: 'student'
        },
        tasks: a_collection_including(
          deleted_reading_task, reading_task # the un-opened homework_task is not included
        )
      )
    end

    it "works for a teacher" do
      outputs = described_class.call(course: course, role: teacher_role,
                                     start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz).outputs

      expect(outputs).to match a_hash_including(
        course: {
          id: course.id,
          name: 'Physics 101',
          teachers: [
            {
              id: teacher_role.teacher.id.to_s,
              role_id: teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart',
              deleted_at: nil
            }
          ]
        },
        role: {
          id: teacher_role.id,
          type: 'teacher'
        },
        tasks: [],
        plans: [
          a_hash_including(
            id: plan.id,
            title: plan.title,
            type: plan.type,
            description: plan.description,
            is_feedback_immediate: plan.is_feedback_immediate,
            is_draft?: plan.is_draft?,
            is_publishing?: plan.is_publishing?,
            is_published?: plan.is_published?,
            first_published_at: plan.first_published_at,
            last_published_at: plan.last_published_at,
            publish_last_requested_at: plan.publish_last_requested_at,
            publish_job_uuid: plan.publish_job_uuid,
            shareable_url: ShortCode::UrlFor[plan],
            tasking_plans: plan.tasking_plans,
            is_trouble: false
          )
        ]
      )
    end
  end

end

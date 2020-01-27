require 'rails_helper'
require 'vcr_helper'

RSpec.describe GetDashboard, type: :routine, speed: :slow do
  before(:all) do
    @course = FactoryBot.create :course_profile_course, name: 'Physics 101'
    period = FactoryBot.create :course_membership_period, course: @course

    student_user = FactoryBot.create :user
    @student_role = AddUserAsPeriodStudent.call(user: student_user, period: period).outputs.role

    teacher_user = FactoryBot.create(
      :user, first_name: 'Bob', last_name: 'Newhart', full_name: 'Bob Newhart'
    )
    @teacher_role = AddUserAsCourseTeacher.call(user: teacher_user, course: @course).outputs.role
    @teacher_student_role = CreateOrResetTeacherStudent.call(
      user: teacher_user, period: period
    ).outputs.role
  end

  [ :student, :teacher_student ].each do |role_type|
    context "tasks belong to a #{role_type} role" do
      before(:all) do
        DatabaseCleaner.start

        @role = role_type == :teacher_student ? @teacher_student_role : @student_role

        @current_time = @course.time_zone.to_tz.now

        @deleted_reading_task = FactoryBot.create(
          :tasks_task,
          task_type: :reading,
          step_types: [
            :tasks_tasked_reading,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        ).tap do |task|
          task.task_plan.destroy!
          task.destroy!
          task.update_attribute :hidden_at, nil
        end

        @deleted_homework_task = FactoryBot.create(
          :tasks_task,
          task_type: :homework,
          step_types: [
            :tasks_tasked_exercise,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        ).tap do |task|
          task.task_plan.destroy!
          task.destroy!
          task.update_attribute :hidden_at, nil
        end

        @hidden_reading_task = FactoryBot.create(
          :tasks_task,
          task_type: :reading,
          step_types: [
            :tasks_tasked_reading,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        ).tap do |task|
          task.task_plan.destroy!
          task.destroy!
        end

        @hidden_homework_task = FactoryBot.create(
          :tasks_task,
          task_type: :homework,
          step_types: [
            :tasks_tasked_exercise,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        ).tap do |task|
          task.task_plan.destroy!
          task.destroy!
        end

        @future_reading_task = FactoryBot.create(
          :tasks_task,
          task_type: :reading,
          step_types: [
            :tasks_tasked_reading,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role,
          opens_at: @current_time + 1.day
        )

        @future_homework_task = FactoryBot.create(
          :tasks_task,
          task_type: :homework,
          step_types: [
            :tasks_tasked_exercise,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role,
          opens_at: @current_time + 1.day
        )

        @reading_task = FactoryBot.create(
          :tasks_task,
          task_type: :reading,
          step_types: [
            :tasks_tasked_reading,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        )

        @unready_reading_task = FactoryBot.create(
          :tasks_task,
          task_type: :reading,
          step_types: [
            :tasks_tasked_reading,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        )

        @old_unready_reading_task = FactoryBot.create(
          :tasks_task,
          task_type: :reading,
          step_types: [
            :tasks_tasked_reading,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role,
          created_at: Time.current - 601.seconds
        )

        @homework_task = FactoryBot.create(
          :tasks_task,
          task_type: :homework,
          step_types: [
            :tasks_tasked_exercise,
            :tasks_tasked_exercise,
            :tasks_tasked_exercise
          ],
          tasked_to: @role
        )

        @unpublished_reading_plan = FactoryBot.create(
          :tasks_task_plan, owner: @course, type: :reading
        )

        @unpublished_homework_plan = FactoryBot.create(
          :tasks_task_plan, owner: @course, type: :reading
        )
      end
      after(:all)  { DatabaseCleaner.clean }

      context 'with no time period specified' do
        it "works for a #{role_type}" do
          expect(Tasks::IsReady).to receive(:[]) do |tasks:|
            tasks - [ @unready_reading_task, @old_unready_reading_task ]
          end

          outputs = described_class.call(course: @course, role: @role).outputs

          expected_tasks = [
            @deleted_reading_task,
            @deleted_homework_task,
            @reading_task,
            @homework_task,
            @old_unready_reading_task
          ]
          expected_tasks += [ @future_reading_task, @future_homework_task ] \
            if role_type == :teacher_student

          expect(outputs).to match a_hash_including(
            course: {
              id: @course.id,
              name: 'Physics 101',
              teachers: [
                {
                  id: @teacher_role.teacher.id.to_s,
                  role_id: @teacher_role.id.to_s,
                  first_name: 'Bob',
                  last_name: 'Newhart',
                  deleted_at: nil
                }
              ]
            },
            role: {
              id: @role.id,
              type: role_type.to_s
            },
            tasks: a_collection_including(*expected_tasks),
            all_tasks_are_ready: false
          )
        end

        it "works for a teacher" do
          outputs = described_class.call(course: @course, role: @teacher_role).outputs

          expect(outputs).to match a_hash_including(
            course: {
              id: @course.id,
              name: 'Physics 101',
              teachers: [
                {
                  id: @teacher_role.teacher.id.to_s,
                  role_id: @teacher_role.id.to_s,
                  first_name: 'Bob',
                  last_name: 'Newhart',
                  deleted_at: nil
                }
              ]
            },
            role: {
              id: @teacher_role.id,
              type: 'teacher'
            },
            tasks: [],
            plans: a_collection_including(
              a_hash_including(
                id: @unpublished_reading_plan.id,
                title: @unpublished_reading_plan.title,
                type: @unpublished_reading_plan.type,
                description: @unpublished_reading_plan.description,
                is_draft?: @unpublished_reading_plan.is_draft?,
                is_publishing?: @unpublished_reading_plan.is_publishing?,
                is_published?: @unpublished_reading_plan.is_published?,
                first_published_at: @unpublished_reading_plan.first_published_at,
                last_published_at: @unpublished_reading_plan.last_published_at,
                publish_last_requested_at: @unpublished_reading_plan.publish_last_requested_at,
                publish_job_uuid: @unpublished_reading_plan.publish_job_uuid,
                shareable_url: ShortCode::UrlFor[@unpublished_reading_plan],
                tasking_plans: @unpublished_reading_plan.tasking_plans,
                is_trouble: false
              ),
              a_hash_including(
                id: @unpublished_homework_plan.id,
                title: @unpublished_homework_plan.title,
                type: @unpublished_homework_plan.type,
                description: @unpublished_homework_plan.description,
                is_draft?: @unpublished_homework_plan.is_draft?,
                is_publishing?: @unpublished_homework_plan.is_publishing?,
                is_published?: @unpublished_homework_plan.is_published?,
                first_published_at: @unpublished_homework_plan.first_published_at,
                last_published_at: @unpublished_homework_plan.last_published_at,
                publish_last_requested_at: @unpublished_homework_plan.publish_last_requested_at,
                publish_job_uuid: @unpublished_homework_plan.publish_job_uuid,
                shareable_url: ShortCode::UrlFor[@unpublished_homework_plan],
                tasking_plans: @unpublished_homework_plan.tasking_plans,
                is_trouble: false
              )
            ),
            all_tasks_are_ready: true
          )
        end

        it "only includes non-deleted surveys" do
          existing_survey = FactoryBot.create(:research_survey, student: @role.student)
          deleted_survey = FactoryBot.create(:research_survey, student: @role.student)
          deleted_survey.destroy

          outputs = described_class.call(course: @course, role: @role).outputs

          expect(outputs.research_surveys.map(&:id)).to eq [ existing_survey.id ]
        end if role_type == :student
      end

      context 'with a time period specified' do
        before(:all) do
          @start_at_ntz = DateTimeUtilities.remove_tz @current_time - 1.week
          @end_at_ntz = DateTimeUtilities.remove_tz @current_time + 1.week + 1.day
        end

        it "works for a #{role_type}" do
          outputs = described_class.call(
            course: @course, role: @role,
            start_at_ntz: @start_at_ntz, end_at_ntz: @end_at_ntz
          ).outputs

          expected_tasks = role_type == :teacher_student ?
            [ @future_reading_task, @future_homework_task ] : []

          expect(outputs).to match a_hash_including(
            course: {
              id: @course.id,
              name: 'Physics 101',
              teachers: [
                {
                  id: @teacher_role.teacher.id.to_s,
                  role_id: @teacher_role.id.to_s,
                  first_name: 'Bob',
                  last_name: 'Newhart',
                  deleted_at: nil
                }
              ]
            },
            role: {
              id: @role.id,
              type: role_type.to_s
            },
            tasks: a_collection_including(*expected_tasks),
            all_tasks_are_ready: true
          )
        end

        it "works for a teacher" do
          outputs = described_class.call(
            course: @course, role: @teacher_role,
            start_at_ntz: @start_at_ntz, end_at_ntz: @end_at_ntz
          ).outputs

          expect(outputs).to match a_hash_including(
            course: {
              id: @course.id,
              name: 'Physics 101',
              teachers: [
                {
                  id: @teacher_role.teacher.id.to_s,
                  role_id: @teacher_role.id.to_s,
                  first_name: 'Bob',
                  last_name: 'Newhart',
                  deleted_at: nil
                }
              ]
            },
            role: {
              id: @teacher_role.id,
              type: 'teacher'
            },
            tasks: [],
            plans: a_collection_including(
              a_hash_including(
                id: @unpublished_reading_plan.id,
                title: @unpublished_reading_plan.title,
                type: @unpublished_reading_plan.type,
                description: @unpublished_reading_plan.description,
                is_draft?: @unpublished_reading_plan.is_draft?,
                is_publishing?: @unpublished_reading_plan.is_publishing?,
                is_published?: @unpublished_reading_plan.is_published?,
                first_published_at: @unpublished_reading_plan.first_published_at,
                last_published_at: @unpublished_reading_plan.last_published_at,
                publish_last_requested_at: @unpublished_reading_plan.publish_last_requested_at,
                publish_job_uuid: @unpublished_reading_plan.publish_job_uuid,
                shareable_url: ShortCode::UrlFor[@unpublished_reading_plan],
                tasking_plans: @unpublished_reading_plan.tasking_plans,
                is_trouble: false
              ),
              a_hash_including(
                id: @unpublished_homework_plan.id,
                title: @unpublished_homework_plan.title,
                type: @unpublished_homework_plan.type,
                description: @unpublished_homework_plan.description,
                is_draft?: @unpublished_homework_plan.is_draft?,
                is_publishing?: @unpublished_homework_plan.is_publishing?,
                is_published?: @unpublished_homework_plan.is_published?,
                first_published_at: @unpublished_homework_plan.first_published_at,
                last_published_at: @unpublished_homework_plan.last_published_at,
                publish_last_requested_at: @unpublished_homework_plan.publish_last_requested_at,
                publish_job_uuid: @unpublished_homework_plan.publish_job_uuid,
                shareable_url: ShortCode::UrlFor[@unpublished_homework_plan],
                tasking_plans: @unpublished_homework_plan.tasking_plans,
                is_trouble: false
              )
            ),
            all_tasks_are_ready: true
          )
        end

        it "only includes non-deleted surveys" do
          existing_survey = FactoryBot.create(:research_survey, student: @role.student)
          deleted_survey = FactoryBot.create(:research_survey, student: @role.student)
          deleted_survey.destroy

          outputs = described_class.call(
            course: @course, role: @role,
            start_at_ntz: @start_at_ntz, end_at_ntz: @end_at_ntz
          ).outputs

          expect(outputs.research_surveys.map(&:id)).to eq [ existing_survey.id ]
        end if role_type == :student
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Api::V1::TaskingPlansController, type: :request, api: true, version: :v1 do
  before(:all) do
    @user = FactoryBot.create(:user_profile)
    @teacher = FactoryBot.create(:user_profile)

    @course = FactoryBot.create :course_profile_course, :with_assistants
    @course.update_attribute :timezone, 'US/Pacific'

    AddUserAsCourseTeacher.call course: @course, user: @teacher

    period = FactoryBot.create :course_membership_period, course: @course

    CreateOrResetTeacherStudent.call user: @teacher, period: period

    @task_plan = FactoryBot.create(
      :tasked_task_plan,
      number_of_students: 1,
      course: @course,
      assistant: get_assistant(course: @course, task_plan_type: 'reading'),
      published_at: Time.current
    )
    @task_plan.grading_template.update_column :manual_grading_feedback_on, :publish
    @tasking_plan = @task_plan.tasking_plans.first
    @tasking_plan.update_attribute :due_at_ntz, Time.current - 1.day
    @not_due_tasking_plan = FactoryBot.create(
      :tasks_tasking_plan,
      task_plan: @task_plan,
      target: FactoryBot.create(:course_membership_period, course: @course)
    )
    DistributeTasks.call task_plan: @task_plan
    @task_plan.tasks.update_all completed_exercise_steps_count: 1

    @student_task = @task_plan.tasks.detect { |task| task.taskings.first.role.student? }
    @teacher_student_task = @task_plan.tasks.detect(&:teacher_student?)

    [ @student_task, @teacher_student_task ].each do |task|
      task.tasked_exercises.update_all(
        grader_points: 1.0, grader_comments: 'Good Job', last_graded_at: Time.current
      )
    end
  end

  context '#grade' do
    let(:valid_json_hash) { Api::V1::TaskPlan::TaskingPlanRepresenter.new(@tasking_plan).to_hash }

    context 'not yet due tasking_plan' do
      it 'does not allow an anonymous user to publish grades' do
        expect do
          api_put grade_api_tasking_plan_url(@not_due_tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to  raise_error(SecurityTransgression)
           .and not_change { @student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.reload.grades_last_published_at }.from(nil)

        [ @student_task, @teacher_student_task ].each do |task|
          task.tasked_exercises.each do |tasked_exercise|
            expect(tasked_exercise.published_points).to be_nil
            expect(tasked_exercise.published_comments).to be_nil
          end
        end
      end

      it 'does not allow an unauthorized user to publish grades' do
        sign_in! @user
        expect do
          api_put grade_api_tasking_plan_url(@not_due_tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to  raise_error(SecurityTransgression)
           .and not_change { @student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.reload.grades_last_published_at }.from(nil)

        [ @student_task, @teacher_student_task ].each do |task|
          task.tasked_exercises.each do |tasked_exercise|
            expect(tasked_exercise.published_points).to be_nil
            expect(tasked_exercise.published_comments).to be_nil
          end
        end
      end

      it 'does not allow a teacher to publish grades' do
        sign_in! @teacher
        expect do
          api_put grade_api_tasking_plan_url(@not_due_tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to  raise_error(SecurityTransgression)
           .and not_change { @student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.reload.grades_last_published_at }.from(nil)

        [ @student_task, @teacher_student_task ].each do |task|
          task.tasked_exercises.each do |tasked_exercise|
            expect(tasked_exercise.published_points).to be_nil
            expect(tasked_exercise.published_comments).to be_nil
          end
        end
      end

      it 'does not call the Glicko update routines' do
        expect(Ratings::UpdatePeriodBookParts).not_to receive(:set)

        expect(Ratings::UpdateRoleBookParts).not_to receive(:set)

        sign_in! @teacher
        expect do
          api_put grade_api_tasking_plan_url(@not_due_tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to  raise_error(SecurityTransgression)
      end
    end

    context 'past-due tasking_plan' do
      it 'does not allow an anonymous user to publish grades' do
        expect do
          api_put grade_api_tasking_plan_url(@tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to raise_error(SecurityTransgression)
           .and not_change { @student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.reload.grades_last_published_at }.from(nil)

        [ @student_task, @teacher_student_task ].each do |task|
          task.tasked_exercises.each do |tasked_exercise|
            expect(tasked_exercise.published_points).to be_nil
            expect(tasked_exercise.published_comments).to be_nil
          end
        end
      end

      it 'does not allow an unauthorized user to publish grades' do
        sign_in! @user
        expect do
          api_put grade_api_tasking_plan_url(@tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to raise_error(SecurityTransgression)
           .and not_change { @student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.reload.grades_last_published_at }.from(nil)

        [ @student_task, @teacher_student_task ].each do |task|
          task.tasked_exercises.each do |tasked_exercise|
            expect(tasked_exercise.published_points).to be_nil
            expect(tasked_exercise.published_comments).to be_nil
          end
        end
      end

      it 'allows a teacher to publish grades for a tasking_plan for their course' do
        sign_in! @teacher
        expect do
          api_put grade_api_tasking_plan_url(@tasking_plan.id), nil,
                  params: valid_json_hash.to_json
        end.to  change     { @student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.reload.grades_last_published_at }.from(nil)
           .and not_change { @teacher_student_task.published_points }.from(0.0)
        expect(response).to have_http_status(:success)
        expect(response.body).to(
          eq(Api::V1::TaskPlan::TaskingPlanRepresenter.new(@tasking_plan.reload).to_json)
        )

        @student_task.tasked_exercises.each do |tasked_exercise|
          expect(tasked_exercise.published_points).to eq 1.0
          expect(tasked_exercise.published_comments).to eq 'Good Job'
        end
        @teacher_student_task.tasked_exercises.each do |tasked_exercise|
          expect(tasked_exercise.published_points).to be_nil
          expect(tasked_exercise.published_comments).to be_nil
        end
      end

      it 'calls the Glicko update routines when fully graded and grades are published' do
        expect(Ratings::UpdatePeriodBookParts).to(
          receive(:set).with(queue: :dashboard).and_return(Ratings::UpdatePeriodBookParts)
        )
        expect(Ratings::UpdatePeriodBookParts).to receive(:perform_later)

        expect(Ratings::UpdateRoleBookParts).to(
          receive(:set).with(queue: :dashboard).and_return(Ratings::UpdateRoleBookParts)
        )
        expect(Ratings::UpdateRoleBookParts).to receive(:perform_later)

        sign_in! @teacher
        api_put grade_api_tasking_plan_url(@tasking_plan.id), nil,
                params: valid_json_hash.to_json

        expect(@student_task.reload.manual_grading_complete?).to eq true
      end
    end
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.find_by(tasks_task_plan_type: task_plan_type).assistant
  end
end

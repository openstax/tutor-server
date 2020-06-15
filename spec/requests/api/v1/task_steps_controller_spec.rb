require 'rails_helper'

RSpec.describe Api::V1::TaskStepsController, type: :request, api: true, version: :v1 do
  before(:all) do
    @course = FactoryBot.create :course_profile_course
    @period = FactoryBot.create :course_membership_period, course: @course

    application = FactoryBot.create :doorkeeper_application

    @user_1 = FactoryBot.create :user_profile
    @user_1_role = AddUserAsPeriodStudent[user: @user_1, period: @period]
    expires_in = @user_1_role.student.payment_due_at + 1.day + 1.hour - Time.current
    @user_1_token = FactoryBot.create :doorkeeper_access_token, application: application,
                                                                resource_owner_id: @user_1.id,
                                                                expires_in: expires_in

    user_2 = FactoryBot.create :user_profile
    @user_2_token = FactoryBot.create :doorkeeper_access_token, application: application,
                                                                resource_owner_id: user_2.id

    @task_step = FactoryBot.create(
      :tasks_task_step, title: 'title', url: 'http://u.rl', content: 'content'
    )
    FactoryBot.create :tasks_tasking, role: @user_1_role, task: @task_step.task
    @task = @task_step.task.reload
    @tasked_exercise = FactoryBot.build(:tasks_tasked_exercise).tap do |te|
      te.task_step.task = @task
      te.save!
    end

    lo = FactoryBot.create :content_tag, value: 'ost-tag-lo-test-lo01'
    pp = FactoryBot.create :content_tag, value: 'os-practice-problems'

    related_exercise = FactoryBot.create :content_exercise, tags: [lo.value, pp.value]

    content = OpenStax::Exercises::V1::FakeClient.new_exercise_hash(tags: [lo.value]).to_json
    ce = FactoryBot.build :content_exercise, content: content
    @tasked_exercise_with_related = FactoryBot.build(
      :tasks_tasked_exercise, exercise: ce
    ).tap do |te|
      te.task_step.task = @task
      te.task_step.related_exercise_ids = [related_exercise.id]
      te.save!
    end

    teacher_user = FactoryBot.create(:user_profile)
    AddUserAsCourseTeacher[course: @course, user: teacher_user]
    @teacher_user_token = FactoryBot.create(
      :doorkeeper_access_token, application: application, resource_owner_id: teacher_user.id
    )
  end

  before do
    @course.reload

    @user_1.reload
    @user_1_role.reload
    @user_1_token.reload

    @user_2_token.reload

    @task_step.reload
    @task.reload
    @tasked_exercise.reload

    @tasked_exercise_with_related.reload

    @teacher_user_token.reload
  end

  context '#show' do
    it 'should work on the happy path' do
      api_get api_step_url(@task_step.id), @user_1_token

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to include(
        id: @task_step.id,
        has_learning_objectives: false,
        type: 'reading',
        title: 'title',
        chapter_section: @task_step.tasked.book_location,
        is_completed: false,
        content_url: 'http://u.rl',
        html: '<body><p>content</p></body>',
        related_content: a_kind_of(Array)
      )
    end

    context 'student' do
      it "422's if needs to pay" do
        make_payment_required_and_expect_422(course: @course, user: @user_1) do
          api_get api_step_url(@task_step.id), @user_1_token
        end
      end
    end

    context 'teacher' do
      it 'does not 422 if needs to pay' do
        make_payment_required_and_expect_not_422(course: @course, user: @user_1) do
          api_get api_step_url(@task_step.id), @teacher_user_token
        end
      end
    end

    it 'raises SecurityTransgression when user is anonymous or not a teacher' do
      expect do
        api_get api_step_url(@task_step.id), nil
      end.to raise_error(SecurityTransgression)

      expect do
        api_get api_step_url(@task_step.id), @user_2_token
      end.to raise_error(SecurityTransgression)
    end

    context 'placeholder step' do
      let!(:placeholder) do
        FactoryBot.create(:tasks_tasked_placeholder, skip_task: true).tap do |placeholder|
          placeholder.task_step.task = @task
          placeholder.save!
        end
      end

      it 'does not replace them and does not blow up' do
        api_get api_step_url(placeholder.task_step.id), @user_1_token

        expect(response).to be_ok
        expect(response.body_as_hash).to include(type: 'placeholder')
      end
    end
  end

  context '#update' do
    let(:tasked) do
      FactoryBot.create(:tasks_tasked_exercise).tap do |tasked|
        FactoryBot.create :tasks_tasking, role: @user_1_role, task: tasked.task_step.task
      end
    end

    it 'updates the free response of an exercise' do
      answer_id = tasked.answer_ids.first

      api_put api_step_url(tasked.task_step.id), @user_1_token,
              params: { free_response: 'Ipsum lorem', answer_id: answer_id.to_s }.to_json
      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to(
        include(answer_id: answer_id.to_s, free_response: 'Ipsum lorem')
      )

      expect(tasked.reload.free_response).to eq 'Ipsum lorem'
    end

    it "422's if needs to pay" do
      make_payment_required_and_expect_422(course: @course, user: @user_1) {
        api_put api_step_url(tasked.task_step.id), @user_1_token,
                params: { free_response: 'Ipsum lorem' }.to_json
      }
    end

    it 'updates the selected answer of an exercise' do
      tasked.free_response = 'Ipsum lorem'
      tasked.save!
      answer_id = tasked.answer_ids.first

      api_put api_step_url(tasked.task_step.id), @user_1_token,
              params: { answer_id: answer_id.to_s }.to_json

      expect(response).to have_http_status(:success)

      expect(tasked.reload.answer_id).to eq answer_id
      task_step = tasked.task_step
      expect(task_step.first_completed_at).not_to be_nil
      expect(task_step.last_completed_at).not_to be_nil
    end

    it 'does not update the answer if the free response is not set' do
      answer_id = tasked.answer_ids.first

      api_put api_step_url(tasked.task_step.id), @user_1_token,
              params: { answer_id: answer_id.to_s }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tasked.reload.answer_id).to be_nil
    end

    it 'returns an error when the free response is blank' do
      api_put api_step_url(tasked.task_step.id), @user_1_token,
              params: { free_response: ' ' }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'updates last_completed_at if the step is already completed' do
      tasked.free_response = 'Ipsum Lorem'
      tasked.answer_id = tasked.answer_ids.first
      tasked.save!
      task_step = tasked.task_step
      completed_at = Time.current - 1.second
      task_step.complete! completed_at: completed_at
      expect(task_step.first_completed_at).to eq completed_at
      expect(task_step.last_completed_at).to eq completed_at
      task_step.task.task_plan.grading_template.update_attribute :auto_grading_feedback_on, :due

      expect do
        api_put api_step_url(tasked.task_step.id), @user_1_token,
                params: { answer_id: tasked.answer_ids.last }.to_json
      end.to change { tasked.reload.answer_id }

      expect(response).to have_http_status(:success)
      task_step.reload
      expect(task_step.last_completed_at).not_to be_nil
      expect(task_step.last_completed_at).not_to eq completed_at
      expect(tasked.answer_id).to eq tasked.answer_ids.last
      expect(tasked.free_response).to eq 'Ipsum Lorem'
    end

    context 'research' do
      let!(:study)  { FactoryBot.create :research_study }
      let!(:cohort) { FactoryBot.create :research_cohort, name: 'control', study: study }
      before(:each) do
        Research::AddCourseToStudy[course: @course, study: study]
      end

      it 'can override requiring free-response format' do
        expect(tasked.parser.question_formats_for_students).to eq [
          'multiple-choice', 'free-response'
        ]
        FactoryBot.create :research_modified_tasked, study: study, code: <<~EOC
          tasked.parser.questions_for_students.each{|q|
            q['formats'] -= ['free-response']
          } if tasked.exercise? && cohort.name == 'control'
          manipulation.record!
        EOC
        study.activate!

        api_put api_step_url(tasked.task_step.id), @user_1_token,
                params: { free_response: '', answer_id: tasked.answer_ids.first }.to_json

        expect(response).to have_http_status(:success)
      end
    end

    context 'practice task' do
      let(:step) do
        page = @tasked_exercise.exercise.page

        FactoryBot.create :content_exercise, page: page

        Content::Routines::PopulateExercisePools[book: page.book]

        AddEcosystemToCourse[course: @course, ecosystem: page.ecosystem]

        FindOrCreatePracticeSpecificTopicsTask[
          course: @course, role: @user_1_role, page_ids: [page.id]
        ].task_steps.first
      end

      it 'allows updating of a step' do
        api_put api_step_url(step.id), @user_1_token, params: {
                  free_response: 'Ipsum lorem', answer_id: step.tasked.answer_ids.first
                }.to_json

        expect(response).to have_http_status(:success)
      end

      it "422's if needs to pay" do
        make_payment_required_and_expect_422(course: @course, user: @user_1) {
          api_put api_step_url(step.id), @user_1_token,
                  params: { free_response: 'Ipsum lorem' }.to_json
        }
      end
    end
  end

  context '#grade' do
    let(:tasked)       do
      FactoryBot.create(:tasks_tasked_exercise).tap do |tasked|
        FactoryBot.create :tasks_tasking, role: @user_1_role, task: tasked.task_step.task
      end
    end
    let(:task_step)    { tasked.task_step }
    let(:task)         { task_step.task }
    let(:task_plan)    { task.task_plan }
    let(:tasking_plan) { task_plan.tasking_plans.first }

    before do
      tasking_plan.update_attribute :target, @period

      tasked.answer_ids = []
      tasked.free_response = 'A sentence explaining all the things!'
      tasked.save!
      MarkTaskStepCompleted.call task_step: task_step

      expect(task.gradable_step_count).to eq 1
      expect(task.ungraded_step_count).to eq 1
      expect(tasking_plan.reload.gradable_step_count).to eq 1
      expect(tasking_plan.ungraded_step_count).to eq 1
      expect(task_plan.reload.gradable_step_count).to eq 1
      expect(task_plan.ungraded_step_count).to eq 1
    end

    context 'task not yet due' do
      it 'raises SecurityTransgression' do
        expect do
          api_put grade_api_step_url(task_step.id), @teacher_user_token,
                  params: { grader_points: 42.0, grader_comments: 'Test' }.to_json
        end.to  raise_error(SecurityTransgression)
           .and not_change { tasked.reload.grader_points }
           .and not_change { tasked.grader_comments }
           .and not_change { tasked.last_graded_at }
           .and not_change { tasked.published_points }
           .and not_change { tasked.published_comments }
           .and not_change { task.reload.gradable_step_count }
           .and not_change { task.reload.ungraded_step_count }
           .and not_change { tasking_plan.gradable_step_count }
           .and not_change { tasking_plan.ungraded_step_count }
           .and not_change { task_plan.reload.gradable_step_count }
           .and not_change { task_plan.reload.ungraded_step_count }
      end
    end

    context 'task past-due' do
      before do
        task.opens_at_ntz = Time.current - 1.day
        task.due_at_ntz = Time.current - 1.day
        task.save!
      end

      context "manual_grading_feedback_on == 'grade'" do
        before { task_plan.grading_template.manual_grading_feedback_on_grade! }

        it 'updates the grader fields, published fields and gradable step counts' do
          expect do
            api_put grade_api_step_url(task_step.id), @teacher_user_token,
                    params: { grader_points: 42.0, grader_comments: 'Test' }.to_json
          end.to  change     { tasked.reload.grader_points }.from(nil).to(42.0)
             .and change     { tasked.grader_comments }.from(nil).to('Test')
             .and change     { tasked.last_graded_at }.from(nil)
             .and change     { tasked.reload.published_points }.to(42.0)
             .and change     { tasked.published_comments }.from(nil).to('Test')
             .and not_change { task.reload.gradable_step_count }
             .and change     { task.ungraded_step_count }.by(-1)
             .and not_change { tasking_plan.reload.gradable_step_count }
             .and change     { tasking_plan.ungraded_step_count }.by(-1)
             .and not_change { task_plan.reload.gradable_step_count }
             .and change     { task_plan.ungraded_step_count }.by(-1)
          expect(response).to have_http_status(:success)

          expect(response.body_as_hash).to include(grader_points: 42.0, grader_comments: 'Test')
        end
      end

      context "manual_grading_feedback_on == 'publish'" do
        before { task_plan.grading_template.manual_grading_feedback_on_publish! }

        it 'updates the grader fields and gradable step counts' do
          expect do
            api_put grade_api_step_url(task_step.id), @teacher_user_token,
                    params: { grader_points: 42.0, grader_comments: 'Test' }.to_json
          end.to  change     { tasked.reload.grader_points }.from(nil).to(42.0)
             .and change     { tasked.grader_comments }.from(nil).to('Test')
             .and change     { tasked.last_graded_at }.from(nil)
             .and not_change { tasked.published_points }
             .and not_change { tasked.published_comments }
             .and not_change { task.reload.gradable_step_count }
             .and change     { task.ungraded_step_count }.by(-1)
             .and not_change { tasking_plan.reload.gradable_step_count }
             .and change     { tasking_plan.ungraded_step_count }.by(-1)
             .and not_change { task_plan.reload.gradable_step_count }
             .and change     { task_plan.ungraded_step_count }.by(-1)
          expect(response).to have_http_status(:success)

          expect(response.body_as_hash).to include(grader_points: 42.0, grader_comments: 'Test')
        end
      end
    end
  end

  context 'exercise update progression' do
    before do
      @tasked_exercise.task_step.task.task_plan.grading_template.auto_grading_feedback_on_due!

      @tasked_exercise.task_step.task.update_attribute :opens_at, Time.current.yesterday - 1.day
    end

    it 'only shows feedback and correct answer id after completed and feedback available' do
      api_get(api_step_url(@tasked_exercise.task_step.id), @user_1_token)

      expect(response.body_as_hash).not_to have_key(:solution)
      expect(response.body_as_hash).not_to have_key(:feedback_html)
      expect(response.body_as_hash).not_to have_key(:correct_answer_id)

      @tasked_exercise.free_response = 'abcdefg'
      @tasked_exercise.save!

      api_get(api_step_url(@tasked_exercise.task_step.id), @user_1_token)

      expect(response.body_as_hash).not_to have_key(:solution)
      expect(response.body_as_hash).not_to have_key(:feedback_html)
      expect(response.body_as_hash).not_to have_key(:correct_answer_id)

      correct_answer_id = @tasked_exercise.correct_answer_id
      @tasked_exercise.answer_id = correct_answer_id
      @tasked_exercise.save!

      api_get(api_step_url(@tasked_exercise.task_step.id), @user_1_token)

      expect(response.body_as_hash).not_to have_key(:solution)
      expect(response.body_as_hash).not_to have_key(:feedback_html)
      expect(response.body_as_hash).not_to have_key(:correct_answer_id)

      # save it and then get it again
      api_put(api_step_url(@tasked_exercise.task_step.id), @user_1_token)

      expect(response.body_as_hash).not_to have_key(:solution)
      expect(response.body_as_hash).not_to have_key(:feedback_html)
      expect(response.body_as_hash).not_to have_key(:correct_answer_id)

      api_get(api_step_url(@tasked_exercise.task_step.id), @user_1_token)

      expect(response.body_as_hash).not_to have_key(:solution)
      expect(response.body_as_hash).not_to have_key(:feedback_html)
      expect(response.body_as_hash).not_to have_key(:correct_answer_id)

      # Get it again after feedback is available
      @tasked_exercise.task_step.task.update_attribute :due_at, Time.current.yesterday

      api_get(api_step_url(@tasked_exercise.task_step.id), @user_1_token)

      expect(response.body_as_hash).to include(solution: { content_html: 'The first one.' })
      expect(response.body_as_hash).to include(feedback_html: 'Right!')

      expect(response.body_as_hash).to include(correct_answer_id: correct_answer_id)
    end

    it 'does not allow the answer to be changed after completed and feedback is available' do
      # Initial submission of multiple choice and free response
      answer_id = @tasked_exercise.answer_ids.first
      api_put(api_step_url(@tasked_exercise.task_step.id), @user_1_token,
              params: { free_response: 'My first answer', answer_id: answer_id }.to_json)
      expect(response).to have_http_status(:success)

      @tasked_exercise.reload
      expect(@tasked_exercise.answer_id).to eq answer_id
      expect(@tasked_exercise.free_response).to eq 'My first answer'

      # No feedback yet because feedback date has not been reached
      expect(response.body_as_hash).not_to include(:solution)
      expect(response.body_as_hash).not_to include(:correct_answer_id)
      expect(response.body_as_hash).not_to include(:feedback_html)

      @tasked_exercise.reload
      expect(@tasked_exercise.completed?).to eq true

      # Feedback date has not passed, so the answer can still be updated
      api_put(api_step_url(@tasked_exercise.task_step.id), @user_1_token,
              params: { free_response: 'Something else!' }.to_json)
      expect(response).to have_http_status(:success)

      # The feedback date arrives
      @tasked_exercise.task_step.task.update_attribute :due_at, Time.current.yesterday

      # Free response cannot be changed
      api_put(api_step_url(@tasked_exercise.task_step.id), @user_1_token,
              params: { free_response: 'I changed my mind!' }.to_json)
      expect(response).to have_http_status(:unprocessable_entity)

      @tasked_exercise.reload
      expect(@tasked_exercise.free_response).to eq 'Something else!'

      # Multiple choice cannot be changed
      new_answer_id = @tasked_exercise.answer_ids.last
      expect(new_answer_id).not_to eq @tasked_exercise.answer_id

      api_put(api_step_url(@tasked_exercise.task_step.id), @user_1_token,
              params: { answer_id: new_answer_id }.to_json)
      expect(response).to have_http_status(:unprocessable_entity)

      @tasked_exercise.reload
      expect(@tasked_exercise.answer_id).to eq answer_id
    end
  end
end

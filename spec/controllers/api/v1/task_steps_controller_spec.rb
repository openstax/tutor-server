require "rails_helper"

RSpec.describe Api::V1::TaskStepsController, type: :controller, api: true,
                                             version: :v1, speed: :slow do

  before(:all) do
    @course = FactoryBot.create :course_profile_course
    period = FactoryBot.create :course_membership_period, course: @course

    application = FactoryBot.create :doorkeeper_application

    @user_1 = FactoryBot.create :user
    @user_1_role = AddUserAsPeriodStudent[user: @user_1, period: period]
    expires_in = @user_1_role.student.payment_due_at + 1.day + 1.hour - Time.current
    @user_1_token = FactoryBot.create :doorkeeper_access_token, application: application,
                                                                resource_owner_id: @user_1.id,
                                                                expires_in: expires_in

    user_2 = FactoryBot.create :user
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

    teacher_user = FactoryBot.create(:user)
    AddUserAsCourseTeacher[course: @course, user: teacher_user]
    @teacher_user_token = FactoryBot.create(
      :doorkeeper_access_token, application: application, resource_owner_id: teacher_user.id
    )
  end

  before { @course.reload }

  context "#show" do
    it "should work on the happy path" do
      api_get :show, @user_1_token, parameters: { task_id: @task.id, id: @task_step.id }

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to include(
        id: @task_step.id,
        has_learning_objectives: false,
        type: 'reading',
        title: 'title',
        chapter_section: @task_step.tasked.book_location,
        is_completed: false,
        content_url: 'http://u.rl',
        html: 'content',
        related_content: a_kind_of(Array)
      )
    end

    context 'student' do
      it "422's if needs to pay" do
        make_payment_required_and_expect_422(course: @course, user: @user_1) do
          api_get :show, @user_1_token, parameters: { task_id: @task.id, id: @task_step.id }
        end
      end
    end

    context 'teacher' do
      it 'does not 422 if needs to pay' do
        make_payment_required_and_expect_not_422(course: @course, user: @user_1) do
          api_get :show, @teacher_user_token, parameters: { task_id: @task.id, id: @task_step.id }
        end
      end
    end

    it 'raises SecurityTransgression when user is anonymous or not a teacher' do
      expect do
        api_get :show, nil, parameters: { task_id: @task.id, id: @task_step.id }
      end.to raise_error(SecurityTransgression)

      expect do
        api_get :show, @user_2_token, parameters: { task_id: @task.id, id: @task_step.id }
      end.to raise_error(SecurityTransgression)
    end
  end

  context "PATCH update" do

    let(:tasked)        { create_tasked(:tasked_exercise, @user_1_role) }
    let(:id_parameters) { { task_id: tasked.task_step.task.id, id: tasked.task_step.id } }

    it "updates the free response of an exercise" do
      answer_id = tasked.answer_ids.first

      api_put :update, @user_1_token, parameters: id_parameters,
              raw_post_data: { free_response: "Ipsum lorem",
                               answer_id: answer_id.to_s }
      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to(
        include(answer_id: answer_id.to_s, free_response: "Ipsum lorem")
      )

      expect(tasked.reload.free_response).to eq "Ipsum lorem"
    end

    it "422's if needs to pay" do
      make_payment_required_and_expect_422(course: @course, user: @user_1) {
        api_put :update, @user_1_token, parameters: id_parameters,
                raw_post_data: { free_response: "Ipsum lorem" }
      }
    end

    it "updates the selected answer of an exercise" do
      tasked.free_response = "Ipsum lorem"
      tasked.save!
      answer_id = tasked.answer_ids.first

      api_put :update, @user_1_token,
              parameters: id_parameters, raw_post_data: { answer_id: answer_id.to_s }

      expect(response).to have_http_status(:success)

      expect(tasked.reload.answer_id).to eq answer_id
      task_step = tasked.task_step
      expect(task_step.first_completed_at).not_to be_nil
      expect(task_step.last_completed_at).not_to be_nil
    end

    it "does not update the answer if the free response is not set" do
      answer_id = tasked.answer_ids.first

      api_put :update, @user_1_token,
              parameters: id_parameters, raw_post_data: { answer_id: answer_id.to_s }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tasked.reload.answer_id).to be_nil
    end

    it 'returns an error when the free response is blank' do
      api_put :update, @user_1_token,
              parameters: id_parameters, raw_post_data: { free_response: ' ' }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates last_completed_at if the step is already completed" do
      tasked.free_response = 'Ipsum Lorem'
      tasked.answer_id = tasked.answer_ids.first
      tasked.save!
      task_step = tasked.task_step
      completed_at = Time.current - 1.second
      task_step.complete! completed_at: completed_at
      expect(task_step.first_completed_at).to eq completed_at
      expect(task_step.last_completed_at).to eq completed_at
      task_step.task.update_attribute :feedback_at, Time.current + 1.hour

      expect do
        api_put :update, @user_1_token,
                parameters: id_parameters,
                raw_post_data: { answer_id: tasked.answer_ids.last }
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

      it "can override requiring free-response format" do
        expect(tasked.parser.question_formats_for_students).to eq ["multiple-choice", "free-response"]
        FactoryBot.create :research_modified_tasked, study: study,
                          code: <<~EOC
          tasked.parser.questions_for_students.each{|q|
            q['formats'] -= ['free-response']
          } if tasked.exercise? && cohort.name == 'control'
          manipulation.record!
        EOC
        study.activate!

        api_put :update, @user_1_token,
                parameters: id_parameters, raw_post_data: {
                  free_response: '', answer_id: tasked.answer_ids.first
                }
        expect(response).to have_http_status(:success)
      end

    end

  end

  context "practice task update step" do
    let(:step) do
      page = @tasked_exercise.exercise.page

      Content::Routines::PopulateExercisePools[book: page.book]

      page.practice_widget_pool.update_attribute :content_exercise_ids,
                                                 [@tasked_exercise.content_exercise_id]

      ecosystem = Content::Ecosystem.new strategy: page.ecosystem.wrap

      AddEcosystemToCourse[course: @course, ecosystem: ecosystem]

      CreatePracticeSpecificTopicsTask[
        course: @course, role: @user_1_role, page_ids: [page.id]
      ].task_steps.first
    end

    it "allows updating of a step" do
      api_put :update, @user_1_token, parameters: { id: step.id },
              raw_post_data: { free_response: "Ipsum lorem",
                               answer_id: step.tasked.answer_ids.first }

      expect(response).to have_http_status(:success)
    end

    it "422's if needs to pay" do
      make_payment_required_and_expect_422(course: @course, user: @user_1) {
        api_put :update, @user_1_token, parameters: { id: step.id },
                raw_post_data: { free_response: "Ipsum lorem" }
      }
    end
  end

  # TODO: could replace with FactoryBot calls like in TaskedExercise factory examples
  def create_tasked(type, owner)
    # Make sure the type has the tasks_ prefix
    type = type.to_s.starts_with?("tasks_") ? type : "tasks_#{type}".to_sym
    tasked = FactoryBot.create(type)
    tasking = FactoryBot.create(:tasks_tasking, role: owner, task: tasked.task_step.task)
    tasked
  end

end

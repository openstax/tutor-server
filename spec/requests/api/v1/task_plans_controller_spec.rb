require 'rails_helper'

RSpec.describe Api::V1::TaskPlansController, type: :request, api: true, version: :v1 do
  def get_assistant(course:, task_plan_type:)
    course.course_assistants.find_by(tasks_task_plan_type: task_plan_type).assistant
  end

  before(:all) do
    @course = FactoryBot.create :course_profile_course, :with_assistants
    period = FactoryBot.create :course_membership_period, course: @course

    @user = FactoryBot.create(:user_profile)
    @teacher = FactoryBot.create(:user_profile)
    student = FactoryBot.create(:user_profile)

    @published_task_plan = FactoryBot.build(
      :tasked_task_plan,
      number_of_students: 0,
      course: @course,
      assistant: get_assistant(course: @course, task_plan_type: 'reading'),
      published_at: Time.current
    )
    @published_task_plan.tasking_plans.each do |tasking_plan|
      tasking_plan.update_attribute :opens_at, Time.current - 2.days
    end
    @published_task_plan.save!
    DistributeTasks.call task_plan: @published_task_plan

    @ecosystem = @published_task_plan.ecosystem
    @page = @ecosystem.pages.first

    @task_plan = FactoryBot.build(
      :tasks_task_plan,
      course: @course,
      assistant: get_assistant(course: @course, task_plan_type: 'reading'),
      content_ecosystem_id: @ecosystem.id,
      settings: { page_ids: [ @page.id.to_s ] },
      type: 'reading',
      num_tasking_plans: 0
    )
    FactoryBot.create(
      :tasks_tasking_plan,
      task_plan: @task_plan,
      target: period,
      opens_at: Time.current.tomorrow
    )

    @teacher_student_role = FactoryBot.create(
      :course_membership_teacher_student, period: period
    ).role

    FactoryBot.create :tasks_task, task_plan: @task_plan, tasked_to: [ @teacher_student_role ]

    @course.update_attribute :timezone, 'US/Pacific'

    AddUserAsCourseTeacher.call(course: @course, user: @teacher)
    AddUserAsPeriodStudent.call(period: period, user: student)
  end

  before do
    @published_task_plan.reload
    @task_plan.reload
  end

  context '#index' do
    before do
      @task_plan.destroy!

      sign_in! @teacher
    end

    let(:opts) { { exclude_job_info: true } }

    let!(:orig_course)      { @course }
    let!(:orig_task_plan_1) { @published_task_plan.reload }

    let!(:cloned_course) do
      CloneCourse[course: @course, teacher_user: @teacher, copy_question_library: false].tap do |cc|
        cc.year = @course.year
        cc.starts_at = @course.starts_at
        cc.ends_at = @course.ends_at
        cc.save!

        AddEcosystemToCourse.call ecosystem: @ecosystem, course: cc
      end
    end

    let!(:orig_task_plan_2) do
      FactoryBot.create(:tasks_task_plan,
                        course: orig_course,
                        assistant: get_assistant(course: orig_course, task_plan_type: 'reading'),
                        content_ecosystem_id: @ecosystem.id,
                        settings: { page_ids: [@page.id.to_s] },
                        type: 'reading')
    end

    let!(:cloned_task_plan) do
      FactoryBot.create(:tasks_task_plan,
                        course: cloned_course,
                        assistant: get_assistant(course: cloned_course, task_plan_type: 'reading'),
                        content_ecosystem_id: @ecosystem.id,
                        settings: { page_ids: [@page.id.to_s] },
                        type: 'reading',
                        cloned_from: orig_task_plan_1)
    end

    let!(:orig_task_plan_3) do
      FactoryBot.create(:tasks_task_plan,
                        course: cloned_course,
                        assistant: get_assistant(course: cloned_course, task_plan_type: 'reading'),
                        content_ecosystem_id: @ecosystem.id,
                        settings: { page_ids: [@page.id.to_s] },
                        type: 'reading')
    end

    context 'clone_status == used_source' do
      context 'original course' do
        it 'returns no results' do
          api_get api_course_task_plans_url(orig_course.id, clone_status: 'used_source'), nil

          expect(response.body_as_hash[:items]).to eq []
        end
      end

      context 'cloned course' do
        it 'returns task_plans from the original course that have been cloned' do
          api_get api_course_task_plans_url(cloned_course.id, clone_status: 'used_source'), nil

          expect(response.body_as_hash[:items]).to match_array(
            [ Api::V1::TaskPlan::Representer.new(orig_task_plan_1).as_json(opts).deep_symbolize_keys ]
          )
        end
      end
    end

    context 'clone_status == unused_source' do
      context 'original course' do
        it 'returns no results' do
          api_get api_course_task_plans_url(orig_course.id, clone_status: 'unused_source'), nil

          expect(response.body_as_hash[:items]).to eq []
        end
      end

      context 'cloned course' do
        it 'returns task_plans from the original course that have not been cloned' do
          api_get api_course_task_plans_url(cloned_course.id, clone_status: 'unused_source'), nil

          expect(response.body_as_hash[:items]).to match_array(
            [ Api::V1::TaskPlan::Representer.new(orig_task_plan_2).as_json(opts).deep_symbolize_keys ]
          )
        end
      end
    end

    context 'clone_status == original' do
      context 'original course' do
        it 'returns task_plans from the given course that are not clones' do
          api_get api_course_task_plans_url(orig_course.id, clone_status: 'original'), nil

          expect(response.body_as_hash[:items]).to match_array(
            [
              Api::V1::TaskPlan::Representer.new(orig_task_plan_1).as_json(opts).deep_symbolize_keys,
              Api::V1::TaskPlan::Representer.new(orig_task_plan_2).as_json(opts).deep_symbolize_keys
            ]
          )
        end
      end

      context 'cloned course' do
        it 'returns task_plans from the given course that are not clones' do
          api_get api_course_task_plans_url(cloned_course.id, clone_status: 'original'), nil

          expect(response.body_as_hash[:items]).to match_array(
            [ Api::V1::TaskPlan::Representer.new(orig_task_plan_3).as_json(opts).deep_symbolize_keys ]
          )
        end
      end
    end

    context 'clone_status == clone' do
      context 'original course' do
        it 'returns task_plans from the given course that are clones' do
          api_get api_course_task_plans_url(orig_course.id, clone_status: 'clone'), nil

          expect(response.body_as_hash[:items]).to eq []
        end
      end

      context 'cloned course' do
        it 'returns task_plans from the given course that are clones' do
          api_get api_course_task_plans_url(cloned_course.id, clone_status: 'clone'), nil

          expect(response.body_as_hash[:items]).to match_array(
            [ Api::V1::TaskPlan::Representer.new(cloned_task_plan).as_json(opts).deep_symbolize_keys ]
          )
        end
      end
    end
  end

  context '#show' do
    it 'does not allow an anonymous user to view the task_plan' do
      expect { api_get api_task_plan_url(@task_plan.id), nil }.to raise_error(SecurityTransgression)
    end

    it 'does not allow an unauthorized user to view the task_plan' do
      sign_in! @user
      expect { api_get api_task_plan_url(@task_plan.id), nil }.to raise_error(SecurityTransgression)
    end

    it "allows a teacher to view their course's task_plan" do
      sign_in! @teacher
      api_get api_task_plan_url(@task_plan.id), nil
      expect(response).to have_http_status(:success)

      # Ignore the stats for this test
      expect(response.body_as_hash.except(:stats).to_json).to(
        eq(Api::V1::TaskPlan::Representer.new(@task_plan.reload).to_json)
      )
    end

    it 'does not include stats' do
      sign_in! @teacher
      api_get api_task_plan_url(@task_plan.id), nil
      expect(response.body_as_hash[:stats]).to be_nil
    end
  end

  context '#create' do
    let(:valid_json_hash) { Api::V1::TaskPlan::Representer.new(@task_plan).to_hash }

    it 'does not allow an anonymous user to create a task_plan' do
      expect {
        api_post api_course_task_plans_url(@course.id), nil,
                 params: Api::V1::TaskPlan::Representer.new(@task_plan).to_json
      }.to raise_error(SecurityTransgression)
    end

    it 'does not allow an unauthorized user to create a task_plan' do
      sign_in! @user
      expect {
        api_post api_course_task_plans_url(@course.id), nil,
                 params: Api::V1::TaskPlan::Representer.new(@task_plan).to_json
      }.to raise_error(SecurityTransgression)
    end

    it 'allows a teacher to create a task_plan for their course' do
      sign_in! @teacher
      expect { api_post api_course_task_plans_url(@course.id), nil,
                        params: valid_json_hash.to_json }
        .to change { Tasks::Models::TaskPlan.count }.by(1)
      expect(response).to have_http_status(:success)

      expect(response.body).to eq(
        Api::V1::TaskPlan::Representer.new(Tasks::Models::TaskPlan.order(:created_at).last).to_json
      )
    end

    it 'automatically creates preview tasks' do
      sign_in! @teacher
      expect { api_post api_course_task_plans_url(@course.id), nil,
                        params: valid_json_hash.to_json }
        .to change { @teacher_student_role.taskings.count }.by(1)
      expect(response).to have_http_status(:success)

      expect(@task_plan).not_to be_out_to_students
    end

    it 'does not allow the teacher to create a task_plan with no tasking_plans' do
      sign_in! @teacher

      expect do
        api_post api_course_task_plans_url(@course.id), nil,
                 params: valid_json_hash.merge('tasking_plans' => []).to_json
      end.not_to change { Tasks::Models::TaskPlan.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'tasking_plans_cant_be_blank'
    end

    it 'fails if no Assistant found' do
      sign_in! @teacher

      expect {
        api_post api_course_task_plans_url(@course.id), nil,
                 params: Api::V1::TaskPlan::Representer.new(@task_plan).to_hash.except('type').to_json
      }.to raise_error(IllegalState).and not_change { Tasks::Models::TaskPlan.count }
    end

    context 'when is_publish_requested is set' do
      let(:valid_json_hash) do
        Api::V1::TaskPlan::Representer.new(@task_plan).to_hash.merge('is_publish_requested' => true)
      end

      it 'allows a teacher to publish a task_plan for their course' do
        sign_in! @teacher
        start_time = Time.current
        expect do
          api_post api_course_task_plans_url(@course.id), nil, params: valid_json_hash.to_json
        end.to  change { Tasks::Models::TaskPlan.count }.by(1)
           .and change { Tasks::Models::Task.count     }.by(2)
        end_time = Time.current
        expect(response).to have_http_status(:success)
        new_task_plan = Tasks::Models::TaskPlan.find(response.body_as_hash[:id])
        expect(new_task_plan.publish_last_requested_at).to be > start_time
        expect(new_task_plan.first_published_at).to be > new_task_plan.publish_last_requested_at
        expect(new_task_plan.first_published_at).to be < end_time
        expect(new_task_plan.last_published_at).to eq new_task_plan.first_published_at

        # Revert task_plan to its state when the job was queued so we can check the representation
        new_task_plan.is_publish_requested = true
        new_task_plan.first_published_at = nil
        new_task_plan.last_published_at = nil
        new_task_plan.tasks = []
        expect(response.body).to eq Api::V1::TaskPlan::Representer.new(new_task_plan).to_json

        expect(response.body_as_hash[:publish_job_url]).to include('/api/jobs/')
      end

      it 'returns an error message if the task_plan settings are invalid' do
        invalid_json_hash = valid_json_hash
        invalid_json_hash['settings']['exercises'] = []
        invalid_json_hash['settings']['exercises_count_dynamic'] = 3

        sign_in! @teacher
        expect { api_post api_course_task_plans_url(@course.id), nil,
                          params: invalid_json_hash.to_json }
          .not_to change{ Tasks::Models::TaskPlan.count }
        expect(response).to have_http_status(:unprocessable_entity)
        error = response.body_as_hash[:errors].first
        expect(error[:message]).to include "Settings - The property '#/' contains additional properties [\"exercises\", \"exercises_count_dynamic\"] outside of the schema when none are allowed in schema"
      end
    end

    context 'when cloned_from_id is set' do
      let!(:original_task_plan) do
        FactoryBot.create(
          :tasked_task_plan,
          number_of_students: 0,
          published_at: Time.current
        )
      end
      let(:new_grading_template) do
        FactoryBot.create(
          :tasks_grading_template,
          course: @course,
          task_plan_type: original_task_plan.type,
          cloned_from: original_task_plan.grading_template
        )
      end

      # The FE is responsible for updating the tasking_plans to point to the new course's periods
      # and the grading templates so that's what we emulate here
      let(:valid_json) do
        Api::V1::TaskPlan::Representer.new(original_task_plan).to_hash.merge(
          'grading_template_id' => new_grading_template.id.to_s,
          'cloned_from_id' => original_task_plan.id.to_s
        ).tap do |hash|
          hash['tasking_plans'].each_with_index do |tasking_plan, index|
            tasking_plan['target_id'] = @course.periods.to_a[index].id.to_s
          end
        end.to_json
      end

      it 'calls UpdateTaskPlanEcosystem and creates a valid cloned TaskPlan' do
        sign_in! @teacher
        expect(UpdateTaskPlanEcosystem).to receive(:call).and_call_original
        expect do
          api_post api_course_task_plans_url(@course.id), nil, params: valid_json
        end.to change { Tasks::Models::TaskPlan.count }.by(1)
        expect(response).to have_http_status(:success)

        expect(response.body).to(
          eq(Api::V1::TaskPlan::Representer.new(Tasks::Models::TaskPlan.last).to_json)
        )
      end
    end

    context 'when cloned_from_id is not set' do
      let(:valid_json) do
        Api::V1::TaskPlan::Representer.new(@task_plan).to_json
      end

      it 'does not call UpdateTaskPlanEcosystem' do
        sign_in! @teacher
        expect(UpdateTaskPlanEcosystem).not_to receive(:call)
        expect do
          api_post api_course_task_plans_url(@course.id), nil, params: valid_json
        end.to change { Tasks::Models::TaskPlan.count }.by(1)
        expect(response).to have_http_status(:success)

        expect(response.body).to(
          eq(Api::V1::TaskPlan::Representer.new(Tasks::Models::TaskPlan.last).to_json)
        )
      end
    end
  end

  context '#update' do
    let(:valid_json_hash) { Api::V1::TaskPlan::Representer.new(@task_plan).to_hash }

    it 'does not allow an anonymous user to update a task_plan' do
      expect { api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an unauthorized user to update a task_plan' do
      sign_in! @user
      expect { api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json }
        .to raise_error(SecurityTransgression)
    end

    it 'allows a teacher to update a task_plan for their course' do
      sign_in! @teacher
      api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json
      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq(Api::V1::TaskPlan::Representer.new(@task_plan.reload).to_json)
      )
    end

    it 'automatically updates preview tasks' do
      old_preview_task = FactoryBot.create :tasks_task, task_plan: @task_plan,
                                                        tasked_to: [@teacher_student_role]

      sign_in! @teacher
      api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json
      expect(response).to have_http_status(:success)

      expect(Tasks::Models::Task.find_by(id: old_preview_task)).to be_nil

      new_preview_task = @task_plan.reload.tasks.to_a.find do |task|
        task.taskings.first.role == @teacher_student_role
      end
      expect(new_preview_task).to be_persisted
      expect(@task_plan).not_to be_out_to_students
    end

    # This covers changing due dates, granting extensions and dropping questions
    it 'automatically updates score caches for all tasks in the task_plan' do
      @published_task_plan.grading_template.update_columns(
        auto_grading_feedback_on: :due,
        late_work_penalty: 1.0,
        late_work_penalty_applied: :immediately
      )

      task = @published_task_plan.tasks.detect(&:student?)
      expect(task).not_to be_past_due
      points = task.available_points
      Preview::WorkTask.call task: task, is_correct: true
      expect(task.published_late_work_point_penalty).to eq 0.0
      expect(task.points).to eq points
      expect(task.published_points).to be_nil
      expect(task.score).to eq 1.0
      expect(task.published_score).to be_nil
      expect(task.provisional_score?).to eq false

      valid_json_hash = Api::V1::TaskPlan::Representer.new(@published_task_plan).to_hash
      valid_json_hash['tasking_plans'].each do |tp|
        tp['due_at'] = DateTimeUtilities.to_api_s(Time.current - 1.day)
      end

      sign_in! @teacher
      api_put api_task_plan_url(@published_task_plan.id), nil, params: valid_json_hash.to_json
      expect(response).to be_successful

      expect(task.reload).to be_past_due
      expect(task.available_points).to eq points
      expect(task.published_late_work_point_penalty).to eq points
      expect(task.points).to eq 0.0
      expect(task.published_points).to eq 0.0
      expect(task.score).to eq 0.0
      expect(task.published_score).to eq 0.0
      expect(task.provisional_score?).to eq false

      valid_json_hash['dropped_questions'] = [
        {
          question_id: task.exercise_steps.first.tasked.question_id.to_s,
          drop_method: 'zeroed'
        }.stringify_keys
      ]
      api_put api_task_plan_url(@published_task_plan.id), nil, params: valid_json_hash.to_json
      expect(response).to be_successful

      expect(task.reload).to be_past_due
      expect(task.available_points).to eq points - 1
      expect(task.published_late_work_point_penalty).to eq points - 1
      expect(task.points).to eq 0.0
      expect(task.published_points).to eq 0.0
      expect(task.score).to eq 0.0
      expect(task.published_score).to eq 0.0
      expect(task.provisional_score?).to eq false

      valid_json_hash['extensions'] = [
        {
          role_id: task.taskings.first.entity_role_id.to_s,
          due_at: DateTimeUtilities.to_api_s(Time.current + 1.day),
          closes_at: DateTimeUtilities.to_api_s(Time.current + 2.days)
        }.stringify_keys
      ]
      api_put api_task_plan_url(@published_task_plan.id), nil, params: valid_json_hash.to_json
      expect(response).to be_successful

      expect(task.reload).not_to be_past_due
      expect(task.available_points).to eq points - 1
      expect(task.published_late_work_point_penalty).to eq 0.0
      expect(task.points).to eq points - 1
      expect(task.published_points).to be_nil
      expect(task.score).to eq 1.0
      expect(task.published_score).to be_nil
      expect(task.provisional_score?).to eq false
    end

    it 'does not allow the teacher to delete all the tasking_plans' do
      sign_in! @teacher
      api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.merge(
        'is_publish_requested' => false, 'tasking_plans' => []
      ).to_json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'tasking_plans_cant_be_blank'
      expect(@task_plan.tasking_plans.reload).not_to be_empty
    end

    context 'when is_publish_requested is set' do
      let(:valid_json_hash) do
        Api::V1::TaskPlan::Representer.new(@task_plan).to_hash.merge('is_publish_requested' => true)
      end

      it 'allows a teacher to publish a task_plan for their course' do
        sign_in! @teacher
        start_time = Time.current

        tasks = @task_plan.tasks
        api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json
        end_time = Time.current
        expect(response).to have_http_status(:accepted)
        # Need to reload the task_plan since publishing it will set the
        # publication dates and change the representation
        @task_plan.reload
        expect(@task_plan.publish_last_requested_at).to be > start_time
        expect(@task_plan.first_published_at).to be > @task_plan.publish_last_requested_at
        expect(@task_plan.first_published_at).to be < end_time
        expect(@task_plan.last_published_at).to eq @task_plan.first_published_at

        # Revert task_plan to its state when the job was queued so we can check the representation
        @task_plan.first_published_at = nil
        @task_plan.last_published_at = nil
        @task_plan.tasks = tasks
        expect(response.body).to eq Api::V1::TaskPlan::Representer.new(@task_plan).to_json

        expect(response.body_as_hash[:publish_job_url]).to include('/api/jobs/')
      end

      it 'does not allow the teacher to delete all the tasking_plans' do
        sign_in! @teacher
        api_put api_task_plan_url(@task_plan.id), nil,
                params: valid_json_hash.merge('tasking_plans' => []).to_json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'tasking_plans_cant_be_blank'
        expect(@task_plan.tasking_plans.reload).not_to be_empty
      end

      it 'does not update first_published_at for task_plans that are already published' do
        sign_in! @teacher

        time_zone = @task_plan.tasking_plans.first.time_zone

        publish_last_requested_at = Time.current
        published_at = Time.current
        publish_job_uuid = SecureRandom.uuid

        @task_plan.publish_last_requested_at = publish_last_requested_at
        @task_plan.first_published_at = published_at
        @task_plan.last_published_at = published_at
        @task_plan.publish_job_uuid = publish_job_uuid
        @task_plan.save!

        sleep(1)

        new_opens_at = time_zone.now.yesterday
        valid_json_hash['tasking_plans'].first['opens_at'] = new_opens_at

        tasks = @task_plan.tasks
        api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json

        expect(response).to have_http_status(:accepted)
        # Need to reload the task_plan since publishing it will set
        # publish_last_requested_at and change the representation
        expect(@task_plan.reload.publish_last_requested_at).not_to(
          be_within(1).of(publish_last_requested_at)
        )
        expect(@task_plan.first_published_at).to be_within(1e-6).of(published_at)
        expect(@task_plan.last_published_at).not_to be_within(1).of(published_at)
        expect(@task_plan.publish_job_uuid).not_to eq publish_job_uuid

        @task_plan.tasks.each { |task| expect(task.opens_at).to be_within(1).of(new_opens_at) }

        # Revert task_plan to its state when the job was queued so we can check the representation
        @task_plan.first_published_at = published_at
        @task_plan.last_published_at = published_at
        @task_plan.tasks = tasks
        expect(response.body).to eq Api::V1::TaskPlan::Representer.new(@task_plan).to_json

        expect(response.body_as_hash[:publish_job_url]).to include('/api/jobs/')
      end

      it 'does not allow the open date to be changed after the assignment is open' do
        sign_in! @teacher

        time_zone = @task_plan.tasking_plans.first.time_zone

        opens_at = time_zone.now

        @task_plan.update_attribute :publish_last_requested_at, Time.current
        @task_plan.tasking_plans.first.update_attribute :opens_at, opens_at

        DistributeTasks[task_plan: @task_plan]

        valid_json_hash['title'] = 'Canceled'
        valid_json_hash['description'] = 'Canceled Assignment'

        new_opens_at = time_zone.now.tomorrow.beginning_of_minute
        new_due_at = new_opens_at + 1.week

        valid_json_hash['tasking_plans'].first['opens_at'] = new_opens_at
        valid_json_hash['tasking_plans'].first['due_at'] = new_due_at

        # Since the task_plan opens_at is now in the past, it can no longer be changed
        expect do
          api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json
        end.to  not_change { @task_plan.reload.tasks.count }
           .and not_change { @task_plan.publish_last_requested_at }
           .and change { @task_plan.last_published_at }
           .and change { @task_plan.publish_job_uuid }
           .and change { @task_plan.title }.to('Canceled')
           .and change { @task_plan.description }.to('Canceled Assignment')
        expect(response).to have_http_status(:accepted)

        @task_plan.tasking_plans.each do |tp|
          expect(tp.opens_at).to be_within(1e-6).of(opens_at)
          expect(tp.due_at).to be_within(1e-6).of(new_due_at)
        end
        @task_plan.tasks.each do |task|
          expect(task.opens_at).to be_within(1e-6).of(opens_at)
          expect(task.due_at).to be_within(1e-6).of(new_due_at)
        end

        # last_published_at in this response is stale
        # we could reload in the controller in dev/test but in the real server
        # the publish won't have happened yet due to background jobs, so no point in doing so
        expect(response.body_as_hash.except(:last_published_at)).to eq(
          Api::V1::TaskPlan::Representer.new(
            @task_plan
          ).to_hash.deep_symbolize_keys.except(:last_published_at)
        )
      end

      it 'returns an error message if the task_plan settings are invalid' do
        invalid_json_hash = valid_json_hash
        invalid_json_hash['settings']['exercises'] = []
        invalid_json_hash['settings']['exercises_count_dynamic'] = 3

        sign_in! @teacher
        api_put api_task_plan_url(@task_plan.id), nil, params: invalid_json_hash.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        error = response.body_as_hash[:errors].first
        expect(error[:message]).to include "Settings - The property '#/' contains additional properties [\"exercises\", \"exercises_count_dynamic\"] outside of the schema when none are allowed in schema"
      end

      it 'returns an error message if the tasking_plans are invalid' do
        invalid_json_hash = valid_json_hash
        invalid_json_hash['tasking_plans'] = [{ target_id: nil, target_type: 'not valid' }]

        sign_in! @teacher
        api_put api_task_plan_url(@task_plan.id), nil, params: invalid_json_hash.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        error = response.body_as_hash[:errors].first
        expect(error[:message]).to include 'Tasking plans is invalid'
      end
    end

    context 'out to students' do
      before(:all) do
        DatabaseCleaner.start

        @task_plan.tasking_plans.each do |tasking_plan|
          tasking_plan.update_attribute :opens_at_ntz, Time.current - 1.day
        end

        DistributeTasks.call task_plan: @task_plan
      end
      after(:all)  { DatabaseCleaner.clean }

      let(:new_grading_template) do
        FactoryBot.create(
          :tasks_grading_template, course: @task_plan.course, task_plan_type: @task_plan.type
        )
      end

      let(:valid_json_hash) do
        Api::V1::TaskPlan::Representer.new(@task_plan).to_hash.merge(
          'title' => 'Something new',
          'description' => 'Changed everything',
          'grading_template_id' => new_grading_template.id.to_s
        )
      end

      it 'allows the teacher to change title, description, and grading_template_id' do
        sign_in! @teacher
        expect do
          api_put api_task_plan_url(@task_plan.id), nil, params: valid_json_hash.to_json
        end.to change  { @task_plan.reload.title }
           .and change { @task_plan.description }
           .and change { @task_plan.grading_template }
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash.except(:last_published_at)).to eq(
          Api::V1::TaskPlan::Representer.new(
            @task_plan
          ).as_json.deep_symbolize_keys.except(:last_published_at)
        )
      end

      it 'does not allow the teacher to change opens_at (update is silently ignored)' do
        invalid_json_hash = valid_json_hash.dup
        invalid_json_hash['tasking_plans'].each do |tasking_plan|
          tasking_plan['opens_at'] = (Time.current + 1.day).iso8601
        end

        sign_in! @teacher
        expect do
          api_put api_task_plan_url(@task_plan.id), nil, params: invalid_json_hash.to_json
        end.to  change     { @task_plan.reload.title }
           .and change     { @task_plan.description }
           .and change     { @task_plan.grading_template }
           .and not_change { @task_plan.tasking_plans.first.opens_at }
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash.except(:last_published_at)).to eq(
          Api::V1::TaskPlan::Representer.new(
            @task_plan
          ).as_json.deep_symbolize_keys.except(:last_published_at)
        )
      end

      it 'does not allow the teacher to change settings (update is rejected)' do
        invalid_json_hash = valid_json_hash.dup
        invalid_json_hash['settings'] = {
          'page_ids' => FactoryBot.create(:content_page, ecosystem: @course.ecosystem).id.to_s
        }

        sign_in! @teacher
        expect do
          api_put api_task_plan_url(@task_plan.id), nil, params: invalid_json_hash.to_json
        end.to  not_change { @task_plan.reload.title }
           .and not_change { @task_plan.description }
           .and not_change { @task_plan.grading_template }
           .and not_change { @task_plan.settings }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context '#destroy' do
    it 'does not allow an anonymous user to destroy a task_plan' do
      expect { api_delete api_task_plan_url(@task_plan.id), nil }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an unauthorized user to destroy a task_plan' do
      sign_in! @user
      expect { api_delete api_task_plan_url(@task_plan.id), nil }
        .to raise_error(SecurityTransgression)
    end

    it 'allows a teacher to destroy a task_plan for their course' do
      sign_in! @teacher
      expect { api_delete api_task_plan_url(@task_plan.id), nil }
        .to change { @task_plan.reload.withdrawn? }.from(false).to(true)
      expect(response).to have_http_status(:success)
      expect(response.body).to eq Api::V1::TaskPlan::Representer.new(@task_plan).to_json
    end

    it 'does not allow a teacher to destroy a task_plan that is already destroyed' do
      @task_plan.destroy!
      sign_in! @teacher
      expect { api_delete api_task_plan_url(@task_plan.id), nil }
        .not_to change{ Tasks::Models::TaskPlan.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq('task_plan_is_already_deleted')
    end
  end

  context '#restore' do
    before(:each) { @task_plan.destroy! }

    it 'does not allow an anonymous user to restore a task_plan' do
      expect { api_put restore_api_task_plan_url(@task_plan.id), nil }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an unauthorized user to restore a task_plan' do
      sign_in! @user
      expect { api_put restore_api_task_plan_url(@task_plan.id), nil }
        .to raise_error(SecurityTransgression)
    end

    it 'allows a teacher to restore a task_plan for their course' do
      sign_in! @teacher
      expect { api_put restore_api_task_plan_url(@task_plan.id), nil }
        .to change{ @task_plan.reload.withdrawn? }.from(true).to(false)
      expect(response).to have_http_status(:success)
      expect(response.body).to eq Api::V1::TaskPlan::Representer.new(@task_plan.reload).to_json
    end

    it 'does not allow a teacher to restore a task_plan that is not destroyed' do
      @task_plan.restore!(recursive: true)
      sign_in! @teacher
      expect { api_put restore_api_task_plan_url(@task_plan.id), nil }
        .not_to change{ Tasks::Models::TaskPlan.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq('task_plan_is_not_deleted')
    end
  end

  context '#stats' do
    it 'cannot be requested by anonymous users' do
      expect {
        api_get stats_api_task_plan_url(@published_task_plan.id), nil
      }.to raise_error(SecurityTransgression)
    end

    it 'cannot be requested by unauthorized users' do
      sign_in! @user
      expect {
        api_get stats_api_task_plan_url(@published_task_plan.id), nil
      }.to raise_error(SecurityTransgression)
    end

    it "can be requested by the course's teacher" do
      sign_in! @teacher
      expect {
        api_get stats_api_task_plan_url(@published_task_plan.id), nil
      }.to_not raise_error
    end

    it 'includes stats' do
      sign_in! @teacher
      api_get stats_api_task_plan_url(@published_task_plan.id), nil
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(response.body_as_hash[:stats]).to be_a(Array)
    end
  end

  context '#scores' do
    it 'cannot be requested by anonymous users' do
      expect {
        api_get scores_api_task_plan_url(@published_task_plan.id), nil
      }.to raise_error(SecurityTransgression)
    end

    it 'cannot be requested by unauthorized users' do
      sign_in! @user
      expect {
        api_get scores_api_task_plan_url(@published_task_plan.id), nil
      }.to raise_error(SecurityTransgression)
    end

    it "can be requested by the course's teacher" do
      sign_in! @teacher
      expect {
        api_get scores_api_task_plan_url(@published_task_plan.id), nil
      }.to_not raise_error
    end

    it 'includes the scores' do
      sign_in! @teacher
      api_get scores_api_task_plan_url(@published_task_plan.id), nil
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(response.body_as_hash[:tasking_plans]).to be_a(Array)
    end
  end
end

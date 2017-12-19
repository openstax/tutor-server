require "rails_helper"

RSpec.describe Api::V1::TasksController, type: :controller, api: true,
                                         version: :v1, speed: :medium do

  let(:course)            { FactoryBot.create :course_profile_course }
  let(:period)            { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan_1)       { FactoryBot.create :tasks_task_plan, owner: course }
  let(:task_1)             { FactoryBot.create :tasks_task, title: 'A Task Title',
                                                task_plan: task_plan_1,
                                                step_types: [:tasks_tasked_reading,
                                                             :tasks_tasked_exercise] }

  let(:application)        { FactoryBot.create :doorkeeper_application }
  let(:user_1)             { FactoryBot.create(:user) }
  let(:user_1_token)       { FactoryBot.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: user_1.id }

  let!(:user_1_role)        { AddUserAsPeriodStudent[user: user_1, period: period] }

  let(:user_2)             { FactoryBot.create(:user) }
  let(:user_2_token)       { FactoryBot.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: user_2.id }

  let(:userless_token)     { FactoryBot.create :doorkeeper_access_token,
                                                application: application }

  let!(:tasking_1)         { FactoryBot.create :tasks_tasking, role: user_1_role, task: task_1 }

  let(:teacher_user)       { FactoryBot.create(:user) }
  let!(:teacher_role)      { AddUserAsCourseTeacher[course: course,
                                                    user: teacher_user] }
  let(:teacher_user_token) { FactoryBot.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: teacher_user.id }

  context "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: {id: task_1.id}
      expect(response.code).to eq '200'
      expect(response.body_as_hash).to include(id: task_1.id.to_s)
      expect(response.body_as_hash).to include(title: 'A Task Title')
      expect(response.body_as_hash).to have_key(:steps)
      expect(response.body_as_hash[:steps][0]).to include(type: 'reading')
      expect(response.body_as_hash[:steps][1]).to include(type: 'exercise')
    end

    it "422's if needs to pay" do
      make_payment_required_and_expect_422(course: course, user: user_1) {
        api_get :show, user_1_token, parameters: {id: task_1.id}
      }
    end

    it 'raises SecurityTransgression when user is anonymous or not a teacher' do
      expect {
        api_get :show, nil, parameters: { id: task_1.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :show, user_2_token, parameters: { id: task_1.id }
      }.to raise_error(SecurityTransgression)
    end
  end

  context "#accept_late_work" do
    context 'withdrawn task_plan' do
      before{ task_1.task_plan.destroy! }

      it 'does not change is_late_work_accepted to true' do
        expect {
          api_put :accept_late_work, teacher_user_token, parameters: {id: task_1.id}
        }.to raise_error(SecurityTransgression)

        expect(task_1.accepted_late_at).to be_nil
      end
    end

    context 'non-withdrawn task_plan' do
      it "changes is_late_work_accepted to true" do
        expect(task_1.accepted_late_at).to be_nil
        api_put :accept_late_work, teacher_user_token, parameters: {id: task_1.id}
        expect(response).to have_http_status(:no_content)
        expect(task_1.reload.accepted_late_at).not_to be_nil
      end

      it "can only be used by teachers" do
        expect {
          api_put :accept_late_work, user_1_token, parameters: {id: task_1.id}
        }.to raise_error(SecurityTransgression)
      end
    end
  end

  context "#reject_late_work" do
    before { task_1.update_attribute :accepted_late_at, Time.current }

    context 'withdrawn task_plan' do
      before{ task_1.task_plan.destroy! }

      it 'does not change is_late_work_accepted to false' do
        expect {
          api_put :reject_late_work, teacher_user_token, parameters: {id: task_1.id}
        }.to raise_error(SecurityTransgression)

        expect(task_1.reload.accepted_late_at).not_to be_nil
      end
    end

    context 'non-withdrawn task_plan' do
      it "changes is_late_work_accepted to false" do
        expect(task_1.accepted_late_at).not_to be_nil
        api_put :reject_late_work, teacher_user_token, parameters: {id: task_1.id}
        expect(response).to have_http_status(:no_content)
        expect(task_1.reload.accepted_late_at).to be_nil
      end

      it "can only be used by teachers" do
        expect {
          api_put :reject_late_work, user_1_token, parameters: {id: task_1.id}
        }.to raise_error(SecurityTransgression)
      end
    end
  end

  context "#destroy" do
    context 'student' do
      let(:token) { user_1_token }

      context 'withdrawn task_plan' do
        before { task_1.task_plan.destroy! }

        it 'hides the task' do
          api_delete :destroy, token, parameters: {id: task_1.id}

          expect(task_1.reload).to be_hidden
        end

        it "422's if needs to pay" do
          make_payment_required_and_expect_422(course: course, user: user_1) {
            api_delete :destroy, token, parameters: {id: task_1.id}
          }
        end
      end

      context 'non-withdrawn task_plan' do
        it 'does not hide the task' do
          expect {
            api_delete :destroy, token, parameters: {id: task_1.id}
          }.to raise_error(SecurityTransgression)

          expect(task_1.reload).not_to be_hidden
        end
      end
    end

    context 'non-student' do
      let(:token) { teacher_user_token }

      before{ task_1.task_plan.destroy! }

      it 'does not hide the task' do
        expect {
          api_delete :destroy, token, parameters: {id: task_1.id}
        }.to raise_error(SecurityTransgression)

        expect(task_1.reload).not_to be_hidden
      end
    end
  end

end

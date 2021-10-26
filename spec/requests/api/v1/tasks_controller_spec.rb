require "rails_helper"

RSpec.describe Api::V1::TasksController, type: :request, api: true, version: :v1 do
  let(:course)             { FactoryBot.create :course_profile_course }
  let(:period)             { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan_1)        { FactoryBot.create :tasks_task_plan, course: course }
  let(:task_1)             do
    FactoryBot.create :tasks_task, title: 'A Task Title',
                                   task_plan: task_plan_1,
                                   step_types: [:tasks_tasked_reading, :tasks_tasked_exercise]
  end

  let(:application)        { FactoryBot.create :doorkeeper_application }
  let(:user_1)             { FactoryBot.create(:user_profile) }
  let(:user_1_token)       do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: user_1.id
  end

  let!(:user_1_role)       { AddUserAsPeriodStudent[user: user_1, period: period] }

  let(:user_2)             { FactoryBot.create(:user_profile) }
  let(:user_2_token)       do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: user_2.id
  end

  let(:userless_token)     { FactoryBot.create :doorkeeper_access_token, application: application }

  let!(:tasking_1)         { FactoryBot.create :tasks_tasking, role: user_1_role, task: task_1 }

  let(:teacher_user)       { FactoryBot.create(:user_profile) }
  let!(:teacher_role)      { AddUserAsCourseTeacher[course: course, user: teacher_user] }
  let(:teacher_user_token) do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: teacher_user.id
  end

  context "#show" do
    it "should work on the happy path" do
      api_get api_task_url(task_1.id), user_1_token
      expect(response.code).to eq '200'
      expect(response.body_as_hash).to include(id: task_1.id.to_s)
      expect(response.body_as_hash).to include(title: 'A Task Title')
      expect(response.body_as_hash).to have_key(:steps)
      expect(response.body_as_hash[:steps][0]).to include(type: 'reading')
      expect(response.body_as_hash[:steps][1]).to include(type: 'exercise')
    end

    context 'student' do
      it "422's if needs to pay" do
        make_payment_required_and_expect_422(course: course, user: user_1) do
          api_get api_task_url(task_1.id), user_1_token
        end
      end
    end

    context 'teacher' do
      it 'does not 422 if needs to pay' do
        make_payment_required_and_expect_not_422(course: course, user: user_1) do
          api_get api_task_url(task_1.id), teacher_user_token
        end
      end
    end

    it 'raises SecurityTransgression when user is anonymous or not a teacher' do
      expect do
        api_get api_task_url(task_1.id), nil
      end.to raise_error(SecurityTransgression)

      expect do
        api_get api_task_url(task_1.id), user_2_token
      end.to raise_error(SecurityTransgression)
    end
  end

  context "#destroy" do
    context 'student' do
      let(:token) { user_1_token }

      context 'withdrawn task_plan' do
        before { task_1.task_plan.destroy! }

        it 'hides the task' do
          api_delete api_task_url(task_1.id), token

          expect(task_1.reload).to be_hidden
        end

        it "422's if needs to pay" do
          make_payment_required_and_expect_422(course: course, user: user_1) {
            api_delete api_task_url(task_1.id), token
          }
        end
      end

      context 'non-withdrawn task_plan' do
        it 'does not hide the task' do
          expect {
            api_delete api_task_url(task_1.id), token
          }.to raise_error(SecurityTransgression)

          expect(task_1.reload).not_to be_hidden
        end
      end
    end

    context 'non-student' do
      let(:token) { teacher_user_token }

      before { task_1.task_plan.destroy! }

      it 'does not hide the task' do
        expect {
          api_delete api_task_url(task_1.id), token
        }.to raise_error(SecurityTransgression)

        expect(task_1.reload).not_to be_hidden
      end
    end
  end
end

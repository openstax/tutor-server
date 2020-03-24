require "rails_helper"

RSpec.describe Api::V1::TasksController, type: :controller, api: true, version: :v1 do

  let(:course)             { FactoryBot.create :course_profile_course }
  let(:period)             { FactoryBot.create :course_membership_period, course: course }

  let(:task_plan_1)        { FactoryBot.create :tasks_task_plan, owner: course }
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
      api_get :show, user_1_token, params: {id: task_1.id}
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
          api_get :show, user_1_token, params: { id: task_1.id }
        end
      end
    end

    context 'research' do
      let!(:study)    { FactoryBot.create :research_study }
      let!(:cohort)   { FactoryBot.create :research_cohort, study: study }
      before(:each) {
        Research::AddCourseToStudy[course: course, study: study]
      }
      it "can hide free-response format" do
        expect(task_1.task_steps[1].tasked.content_hash_for_students['questions'][0]['formats'])
          .to eq ["multiple-choice","free-response"]
        FactoryBot.create :research_modified_task, study: study,
                          code: <<~EOC
          task.task_steps.each{ |ts|
            ts.tasked.parser.questions_for_students.each{|q|
              q['formats'] -= ['free-response']
            } if ts.exercise?
          }
          manipulation.record!
        EOC
        study.activate!

        api_get :show, user_1_token, params: { id: task_1.id }
        expect(
          response.body_as_hash[:steps][1][:formats]
        ).to eq %w{multiple-choice}
      end
    end

    context 'teacher' do
      it 'does not 422 if needs to pay' do
        make_payment_required_and_expect_not_422(course: course, user: user_1) do
          api_get :show, teacher_user_token, params: { id: task_1.id }
        end
      end
    end

    it 'raises SecurityTransgression when user is anonymous or not a teacher' do
      expect do
        api_get :show, nil, params: { id: task_1.id }
      end.to raise_error(SecurityTransgression)

      expect do
        api_get :show, user_2_token, params: { id: task_1.id }
      end.to raise_error(SecurityTransgression)
    end
  end

  context "#destroy" do
    context 'student' do
      let(:token) { user_1_token }

      context 'withdrawn task_plan' do
        before { task_1.task_plan.destroy! }

        it 'hides the task' do
          api_delete :destroy, token, params: {id: task_1.id}

          expect(task_1.reload).to be_hidden
        end

        it "422's if needs to pay" do
          make_payment_required_and_expect_422(course: course, user: user_1) {
            api_delete :destroy, token, params: {id: task_1.id}
          }
        end
      end

      context 'non-withdrawn task_plan' do
        it 'does not hide the task' do
          expect {
            api_delete :destroy, token, params: {id: task_1.id}
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
          api_delete :destroy, token, params: {id: task_1.id}
        }.to raise_error(SecurityTransgression)

        expect(task_1.reload).not_to be_hidden
      end
    end
  end

end

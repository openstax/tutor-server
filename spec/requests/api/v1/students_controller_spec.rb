require 'rails_helper'

RSpec.describe Api::V1::StudentsController, type: :request, api: true, version: :v1 do
  let(:application)       { FactoryBot.create :doorkeeper_application }

  let(:course)            { FactoryBot.create :course_profile_course }
  let(:period)            { FactoryBot.create :course_membership_period, course: course }
  let(:period_2)          { FactoryBot.create :course_membership_period, course: course }

  let(:student_user)      { FactoryBot.create(:user_profile) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }
  let!(:student_original_payment_due_at) { student.payment_due_at }
  let(:student_token)     do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: student_user.id
  end

  let(:teacher_user)      { FactoryBot.create(:user_profile) }
  let!(:teacher)          { AddUserAsCourseTeacher[user: teacher_user, course: course] }
  let(:teacher_token)     do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: teacher_user.id
  end

  let(:student_user_2)    { FactoryBot.create(:user_profile) }
  let(:student_role_2)    { AddUserAsPeriodStudent[user: student_user_2, period: period] }
  let!(:student_2)        { student_role_2.student }

  let(:student_user_3)    { FactoryBot.create(:user_profile) }
  let(:student_role_3)    { AddUserAsPeriodStudent[user: student_user_3, period: period_2] }
  let!(:student_3)        { student_role_3.student }

  let(:userless_token)    do
    FactoryBot.create :doorkeeper_access_token, application: application, resource_owner_id: nil
  end

  context '#update_self' do
    let(:new_id)       { '123456789' }
    let(:valid_body)   { { student_identifier: new_id } }

    def update_self_api_course_student_url(course_id)
      "/api/user/courses/#{course_id}/student"
    end

    context 'caller has an authorization token' do
      context 'caller is a course student' do
        context 'updating the student\'s identifier' do
          it 'always succeeds' do
            FactoryBot.create :course_membership_student, course: course,
                                                           student_identifier: new_id
            api_patch update_self_api_course_student_url(course.id), student_token,
                      params: valid_body.to_json
            expect(response).to have_http_status(:ok)
            expect(response.body_as_hash[:student_identifier]).to eq new_id
            expect(student.reload.student_identifier).to eq new_id
          end

          it "422's if needs to pay" do
            make_payment_required_and_expect_422(course: course, student: student) {
              api_patch update_self_api_course_student_url(course.id), student_token,
                        params: valid_body.to_json
            }
          end
        end
      end

      context 'caller is not a course student' do
        it 'raises SecurityTransgression' do
          expect do
            api_patch update_self_api_course_student_url(course.id), teacher_token,
                      params: valid_body.to_json
          end.to raise_error(SecurityTransgression)
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect do
          api_patch update_self_api_course_student_url(course.id), userless_token,
                    params: valid_body.to_json
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect do
          api_patch update_self_api_course_student_url(course.id), nil,
                    params: valid_body.to_json
        end.to raise_error(SecurityTransgression)
      end
    end
  end

  context '#update' do
    let(:valid_body)   { { period_id: period_2.id.to_s } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        context 'moving the student to another period' do
          it 'succeeds' do
            api_patch api_student_url(student.id), teacher_token, params: valid_body.to_json
            expect(response).to have_http_status(:ok)
            new_student = CourseMembership::Models::Student.find(response.body_as_hash[:id])
            expect(response.body_as_hash).to include({
              id: student.id.to_s,
              first_name: student.first_name,
              last_name: student.last_name,
              name: student.name,
              period_id: period_2.id.to_s,
              role_id: student.entity_role_id.to_s,
              is_active: true
            })
            expect(student.reload.period).to eq period_2
          end

          it "does not 422 if needs to pay" do
            make_payment_required_and_expect_not_422(course: course, student: student) {
              api_patch api_student_url(student.id), teacher_token, params: valid_body.to_json
            }
          end

          context 'and updating the student\'s identifier' do
            let(:new_id) { '123456789' }

            it 'always succeeds' do
              FactoryBot.create :course_membership_student, course: course,
                                                             student_identifier: new_id
              api_patch api_student_url(student.id), teacher_token,
                        params: valid_body.merge(student_identifier: new_id).to_json
              expect(response).to have_http_status(:ok)
              expect(response.body_as_hash[:student_identifier]).to eq(new_id)
              expect(student.reload.student_identifier).to eq(new_id)
              expect(student.reload.period).to eq period_2
            end
          end
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect do
            api_patch api_student_url(student.id), student_token, params: valid_body.to_json
          end.to raise_error(SecurityTransgression)
          expect(student.reload.period).to eq period
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect do
          api_patch api_student_url(student.id), userless_token, params: valid_body.to_json
        end.to raise_error(SecurityTransgression)
        expect(student.reload.period).to eq period
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect do
          api_patch api_student_url(student.id), nil, params: valid_body.to_json
        end.to raise_error(SecurityTransgression)
        expect(student.reload.period).to eq period
      end
    end
  end

  context '#destroy' do
    context 'student is active' do
      context 'caller has an authorization token' do
        context 'caller is a course teacher' do
          it 'removes the student from the course' do
            api_delete api_student_url(student.id), teacher_token
            expect(response).to have_http_status(:ok)
            expect(response.body_as_hash[:is_active]).to eq false

            student.reload
            expect(student.persisted?).to eq true
            expect(student.dropped?).to eq true
          end
        end

        context 'caller is not a course teacher' do
          it 'raises SecurityTransgression' do
            expect do
              api_delete api_student_url(student.id), student_token
            end.to raise_error(SecurityTransgression)
            expect(student.reload.dropped?).to eq false
          end
        end
      end

      context 'caller has an application/client credentials authorization token' do
        it 'raises SecurityTransgression' do
          expect do
            api_delete api_student_url(student.id), userless_token
          end.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq false
        end
      end

      context 'caller does not have an authorization token' do
        it 'raises SecurityTransgression' do
          expect do
            api_delete api_student_url(student.id), nil
          end.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq false
        end
      end
    end

    context 'student is inactive' do
      before { CourseMembership::InactivateStudent[student: student] }

      it 'returns an error' do
        api_delete api_student_url(student.id), teacher_token
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_inactive'
        expect(response.body_as_hash[:errors].first[:message]).to eq 'Student is already inactive'

        student.reload
        expect(student.persisted?).to eq true
        expect(student.dropped?).to eq true
      end
    end
  end

  context '#restore' do
    let(:valid_params) { { id: student.id } }

    context 'student is inactive' do
      before { CourseMembership::InactivateStudent[student: student] }

      context 'caller has an authorization token' do
        context 'caller is a course teacher' do
          context 'restoring a student to the course' do
            it 'succeeds if the student identifier is available' do
              api_put restore_api_student_url(student.id), teacher_token
              expect(response).to have_http_status(:ok)
              expect(response.body_as_hash[:is_active]).to eq true

              student.reload
              expect(student.persisted?).to eq true
              expect(student.dropped?).to eq false
              expect(student.payment_due_at).to eq student_original_payment_due_at
            end

            it 'succeeds even if the student\'s identifier is taken by someone else' do
              student_id = '123456789'
              student.update_attribute :student_identifier, student_id
              FactoryBot.create :course_membership_student, course: course,
                                                            student_identifier: student_id

              api_put restore_api_student_url(student.id), teacher_token
              expect(response).to have_http_status(:ok)
              student.reload
              expect(student.persisted?).to eq true
              expect(student.dropped?).to eq false
            end
          end
        end

        context 'caller is not a course teacher' do
          it 'raises SecurityTransgression' do
            expect do
              api_put restore_api_student_url(student.id), student_token
            end.to raise_error(SecurityTransgression)
            expect(student.reload.dropped?).to eq true
          end
        end
      end

      context 'caller has an application/client credentials authorization token' do
        it 'raises SecurityTransgression' do
          expect do
            api_put restore_api_student_url(student.id), userless_token
          end.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq true
        end
      end

      context 'caller does not have an authorization token' do
        it 'raises SecurityTransgression' do
          expect do
            api_put restore_api_student_url(student.id), nil
          end.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq true
        end
      end

      it 'student gets assignments published while dropped' do
        FactoryBot.create :course_membership_teacher_student, period: period

        task_plan = FactoryBot.build(:tasks_task_plan, course: course).tap do |task_plan|
          task_plan.tasking_plans.first.target = period
          task_plan.save!
        end

        # The teacher publishes an assignment, and the student doesn't get it...
        # TeacherStudent role still gets it
        expect do
          DistributeTasks.call(task_plan: task_plan)
        end.to  change     { Tasks::Models::Tasking.count }.by(2)
           .and not_change { student_user.roles.first.taskings.count }

        # The teacher restores the student and the student gets the missing task
        expect do
          api_put restore_api_student_url(student.id), teacher_token
        end.to  change  { Tasks::Models::Tasking.count }.by(1)
           .and change { student_user.roles.first.taskings.count }.by(1)
      end
    end

    context 'student is active' do
      it 'returns an error' do
        api_put restore_api_student_url(student.id), teacher_token
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_active'
        expect(response.body_as_hash[:errors].first[:message]).to eq 'Student is already active'

        student.reload
        expect(student.persisted?).to eq true
        expect(student.dropped?).to eq false
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Api::V1::StudentsController, type: :controller, api: true, version: :v1 do

  let(:application)       { FactoryGirl.create :doorkeeper_application }

  let(:course)            { FactoryGirl.create :course_profile_course }
  let(:period)            { FactoryGirl.create :course_membership_period, course: course }
  let(:period_2)          { FactoryGirl.create :course_membership_period, course: course }

  let(:student_user)      { FactoryGirl.create(:user) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }
  let!(:student_original_payment_due_at) { student.payment_due_at }
  let(:student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:teacher_user)      { FactoryGirl.create(:user) }
  let!(:teacher)          { AddUserAsCourseTeacher[user: teacher_user, course: course] }
  let(:teacher_token)     { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: teacher_user.id }

  let(:student_user_2)    { FactoryGirl.create(:user) }
  let(:student_role_2)    { AddUserAsPeriodStudent[user: student_user_2, period: period] }
  let!(:student_2)        { student_role_2.student }

  let(:student_user_3)    { FactoryGirl.create(:user) }
  let(:student_role_3)    { AddUserAsPeriodStudent[user: student_user_3, period: period_2] }
  let!(:student_3)        { student_role_3.student }

  let(:userless_token)    { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: nil }

  # TEMPORARILY SKIPPED UNTIL WE RESURRECT THE ABILITY FOR A TEACHER TO ADD A STUDENT
  # SEE STUDENTS CONTROLLER COMMENT
  #
  # describe '#create' do
  #   let(:valid_params) { { course_id: course.id } }
  #   let(:valid_body)   {
  #     {
  #       period_id: period.id.to_s,
  #       username: 'dummyuser',
  #       password: 'pass',
  #       first_name: 'Dummy',
  #       last_name: 'User',
  #       full_name: 'Dummy User'
  #     }
  #   }

  #   context 'caller has an authorization token' do
  #     context 'caller is a course teacher' do
  #       it 'creates a new student' do
  #         expect {
  #           api_post :create, teacher_token, parameters: valid_params, raw_post_data: valid_body
  #         }.to change{ User::Models::Profile.count }.by(1)
  #         expect(response).to have_http_status(:created)
  #         new_student = CourseMembership::Models::Student.find(response.body_as_hash[:id])
  #         expect(response.body_as_hash).to eq({
  #           id: new_student.id.to_s,
  #           username: 'dummyuser',
  #           first_name: 'Dummy',
  #           last_name: 'User',
  #           full_name: 'Dummy User',
  #           period_id: period.id.to_s,
  #           role_id: new_student.entity_role_id.to_s,
  #           is_active: true
  #         })
  #       end
  #     end

  #     context 'caller is not a course teacher' do
  #       it 'raises SecurityTransgression' do
  #         expect {
  #           api_post :create, student_token, parameters: valid_params, raw_post_data: valid_body
  #         }.to raise_error(SecurityTransgression)
  #       end
  #     end
  #   end

  #   context 'caller has an application/client credentials authorization token' do
  #     it 'raises SecurityTransgression' do
  #       expect {
  #         api_post :create, userless_token, parameters: valid_params, raw_post_data: valid_body
  #       }.to raise_error(SecurityTransgression)
  #     end
  #   end

  #   context 'caller does not have an authorization token' do
  #     it 'raises SecurityTransgression' do
  #       expect {
  #         api_post :create, nil, parameters: valid_params, raw_post_data: valid_body
  #       }.to raise_error(SecurityTransgression)
  #     end
  #   end
  # end

  describe '#update_self' do
    let(:valid_params) { { course_id: course.id } }
    let(:new_id)       { '123456789' }
    let(:valid_body)   { { student_identifier: new_id } }

    context 'caller has an authorization token' do
      context 'caller is a course student' do
        context 'updating the student\'s identifier' do
          it 'always succeeds' do
            FactoryGirl.create :course_membership_student, course: course,
                                                           student_identifier: new_id
            api_patch :update_self, student_token, parameters: valid_params,
                                                   raw_post_data: valid_body
            expect(response).to have_http_status(:ok)
            expect(response.body_as_hash[:student_identifier]).to eq new_id
            expect(student.reload.student_identifier).to eq new_id
          end

          it "422's if needs to pay" do
            make_payment_required_and_expect_422(course: course, student: student) {
              api_patch :update_self, student_token, parameters: valid_params,
                                                     raw_post_data: valid_body
            }
          end
        end
      end

      context 'caller is not a course student' do
        it 'raises SecurityTransgression' do
          expect{
            api_patch :update_self, teacher_token, parameters: valid_params,
                                                   raw_post_data: valid_body
          }.to raise_error(SecurityTransgression)
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_patch :update_self, userless_token, parameters: valid_params,
                                                  raw_post_data: valid_body
        }.to raise_error(SecurityTransgression)
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_patch :update_self, nil, parameters: valid_params, raw_post_data: valid_body
        }.to raise_error(SecurityTransgression)
      end
    end
  end

  describe '#update' do
    let(:valid_params) { { id: student.id } }
    let(:valid_body)   { { period_id: period_2.id.to_s } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        context 'moving the student to another period' do
          it 'succeeds' do
            api_patch :update, teacher_token, parameters: valid_params, raw_post_data: valid_body
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
            expect(student.reload.period).to eq period_2.to_model
          end

          it "422's if needs to pay" do
            make_payment_required_and_expect_422(course: course, student: student) {
              api_patch :update, teacher_token, parameters: valid_params, raw_post_data: valid_body
            }
          end

          context 'and updating the student\'s identifier' do
            let(:new_id) { '123456789' }

            it 'always succeeds' do
              FactoryGirl.create :course_membership_student, course: course,
                                                             student_identifier: new_id
              api_patch :update, teacher_token, parameters: valid_params,
                                 raw_post_data: valid_body.merge({ student_identifier: new_id })
              expect(response).to have_http_status(:ok)
              expect(response.body_as_hash[:student_identifier]).to eq(new_id)
              expect(student.reload.student_identifier).to eq(new_id)
              expect(student.reload.period).to eq period_2.to_model
            end
          end
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect{
            api_patch :update, student_token, parameters: valid_params, raw_post_data: valid_body
          }.to raise_error(SecurityTransgression)
          expect(student.reload.period).to eq period.to_model
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_patch :update, userless_token, parameters: valid_params, raw_post_data: valid_body
        }.to raise_error(SecurityTransgression)
        expect(student.reload.period).to eq period.to_model
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_patch :update, nil, parameters: valid_params, raw_post_data: valid_body
        }.to raise_error(SecurityTransgression)
        expect(student.reload.period).to eq period.to_model
      end
    end
  end

  describe '#destroy' do
    let(:valid_params) { { id: student.id } }

    context 'student is active' do
      context 'caller has an authorization token' do
        context 'caller is a course teacher' do
          it 'removes the student from the course' do
            api_delete :destroy, teacher_token, parameters: valid_params
            expect(response).to have_http_status(:ok)
            expect(response.body_as_hash[:is_active]).to eq false

            student.reload
            expect(student.persisted?).to eq true
            expect(student.dropped?).to eq true
          end
        end

        context 'caller is not a course teacher' do
          it 'raises SecurityTransgression' do
            expect{
              api_delete :destroy, student_token, parameters: valid_params
            }.to raise_error(SecurityTransgression)
            expect(student.reload.dropped?).to eq false
          end
        end
      end

      context 'caller has an application/client credentials authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_delete :destroy, userless_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq false
        end
      end

      context 'caller does not have an authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_delete :destroy, nil, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq false
        end
      end
    end

    context 'student is inactive' do
      before { CourseMembership::InactivateStudent[student: student] }

      it 'returns an error' do
        api_delete :destroy, teacher_token, parameters: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_inactive'
        expect(response.body_as_hash[:errors].first[:message]).to eq 'Student is already inactive'

        student.reload
        expect(student.persisted?).to eq true
        expect(student.dropped?).to eq true
      end
    end
  end

  describe '#undrop' do
    let(:valid_params) { { id: student.id } }

    context 'student is inactive' do
      before { CourseMembership::InactivateStudent[student: student] }

      context 'caller has an authorization token' do
        context 'caller is a course teacher' do
          context 'undropping the student from the course' do
            it 'succeeds if the student identifier is available' do
              api_put :undrop, teacher_token, parameters: valid_params
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
              FactoryGirl.create :course_membership_student, course: course,
                                                             student_identifier: student_id

              api_put :undrop, teacher_token, parameters: valid_params
              expect(response).to have_http_status(:ok)
              student.reload
              expect(student.persisted?).to eq true
              expect(student.dropped?).to eq false
            end
          end
        end

        context 'caller is not a course teacher' do
          it 'raises SecurityTransgression' do
            expect{
              api_put :undrop, student_token, parameters: valid_params
            }.to raise_error(SecurityTransgression)
            expect(student.reload.dropped?).to eq true
          end
        end
      end

      context 'caller has an application/client credentials authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_put :undrop, userless_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq true
        end
      end

      context 'caller does not have an authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_put :undrop, nil, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.dropped?).to eq true
        end
      end
    end

    context 'student is active' do
      it 'returns an error' do
        api_put :undrop, teacher_token, parameters: valid_params
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

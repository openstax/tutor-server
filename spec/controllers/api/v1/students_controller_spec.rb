require 'rails_helper'

describe Api::V1::StudentsController, type: :controller, api: true, version: :v1 do

  let!(:application)       { FactoryGirl.create :doorkeeper_application }

  let!(:course)            { Entity::Course.create }
  let!(:period)            { CreatePeriod.call(course: course).period }
  let!(:period_2)          { CreatePeriod.call(course: course).period }

  let!(:student_user)      { FactoryGirl.create(:user) }
  let!(:student_role)      { AddUserAsPeriodStudent.call(user: student_user, period: period).role }
  let!(:student)           { student_role.student }
  let!(:student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: student_user.id }

  let!(:teacher_user)      { FactoryGirl.create(:user) }
  let!(:teacher)           { AddUserAsCourseTeacher.call(user: teacher_user, course: course).role }
  let!(:teacher_token)     { FactoryGirl.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: teacher_user.id }

  let!(:student_user_2)    { FactoryGirl.create(:user) }
  let!(:student_role_2)    { AddUserAsPeriodStudent.call(user: student_user_2, period: period).role }
  let!(:student_2)         { student_role_2.student }

  let!(:student_user_3)    { FactoryGirl.create(:user) }
  let!(:student_role_3)    { AddUserAsPeriodStudent.call(user: student_user_3, period: period_2).role }
  let!(:student_3)         { student_role_3.student }

  let!(:userless_token)    { FactoryGirl.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: nil }

  # TEMPORARILY SKIPPED UNTIL WE RESURRECT THE ABILITY FOR A TEACHER TO ADD A STUDENT
  # SEE STUDENTS CONTROLLER COMMENT
  #
  # describe '#create' do
  #   let!(:valid_params) { { course_id: course.id } }
  #   let!(:valid_body)   {
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
  #           deidentifier: new_student.deidentifier,
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

  describe '#update' do
    let!(:valid_params) { { id: student.id } }
    let!(:valid_body)   { { period_id: period_2.id.to_s } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        it 'moves the student to another period' do
          api_patch :update, teacher_token, parameters: valid_params, raw_post_data: valid_body
          expect(response).to have_http_status(:ok)
          new_student = CourseMembership::Models::Student.find(response.body_as_hash[:id])
          expect(response.body_as_hash).to eq({
            id: student.id.to_s,
            first_name: student.first_name,
            last_name: student.last_name,
            name: student.name,
            period_id: period_2.id.to_s,
            role_id: student.entity_role_id.to_s,
            deidentifier: student.deidentifier,
            is_active: true
          })
          expect(student.reload.period).to eq period_2.to_model
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
    let!(:valid_params) { { id: student.id } }

    context 'student is active' do
      context 'caller has an authorization token' do
        context 'caller is a course teacher' do
          it 'removes the student from the course' do
            api_delete :destroy, teacher_token, parameters: valid_params
            expect(response).to have_http_status(:no_content)

            student.reload
            expect(student.persisted?).to eq true
            expect(student.active?).to eq false
          end
        end

        context 'caller is not a course teacher' do
          it 'raises SecurityTransgression' do
            expect{
              api_delete :destroy, student_token, parameters: valid_params
            }.to raise_error(SecurityTransgression)
            expect(student.reload.destroyed?).to eq false
          end
        end
      end

      context 'caller has an application/client credentials authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_delete :destroy, userless_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.destroyed?).to eq false
        end
      end

      context 'caller does not have an authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_delete :destroy, nil, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.destroyed?).to eq false
        end
      end
    end

    context 'student is inactive' do
      before { CourseMembership::InactivateStudent.call(student: student) }

      it 'returns an error' do
        api_delete :destroy, teacher_token, parameters: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_inactive'

        student.reload
        expect(student.persisted?).to eq true
        expect(student.active?).to eq false
      end
    end
  end

  describe '#undrop' do
    let!(:valid_params) { { id: student.id } }

    context 'student is inactive' do
      before { CourseMembership::InactivateStudent.call(student: student) }

      context 'caller has an authorization token' do
        context 'caller is a course teacher' do
          it 'undrops the student from the course' do
            api_put :undrop, teacher_token, parameters: valid_params
            expect(response).to have_http_status(:ok)
            expect(response.body_as_hash[:is_active]).to be true

            student.reload
            expect(student.persisted?).to eq true
            expect(student.active?).to eq true
          end
        end

        context 'caller is not a course teacher' do
          it 'raises SecurityTransgression' do
            expect{
              api_put :undrop, student_token, parameters: valid_params
            }.to raise_error(SecurityTransgression)
            expect(student.reload.active?).to eq false
          end
        end
      end

      context 'caller has an application/client credentials authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_put :undrop, userless_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.active?).to eq false
        end
      end

      context 'caller does not have an authorization token' do
        it 'raises SecurityTransgression' do
          expect{
            api_put :undrop, nil, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.active?).to eq false
        end
      end
    end

    context 'student is active' do
      it 'returns an error' do
        api_put :undrop, teacher_token, parameters: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_active'

        student.reload
        expect(student.persisted?).to eq true
        expect(student.active?).to eq true
      end
    end
  end

end

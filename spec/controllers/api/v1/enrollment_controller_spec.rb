require 'rails_helper'

RSpec.describe Api::V1::EnrollmentChangesController, type: :controller, api: true, version: :v1 do
  let(:user)                 { FactoryGirl.create :user }

  let(:user_2)               { FactoryGirl.create :user }

  let(:course)               { FactoryGirl.create :course_profile_course, is_concept_coach: true }

  let(:period)               { FactoryGirl.create :course_membership_period, course: course }
  let(:period_2)             { FactoryGirl.create :course_membership_period, course: course }

  let(:book)                 { FactoryGirl.create :content_book }

  let(:ecosystem)            do
    model = book.ecosystem
    strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
    ::Content::Ecosystem.new(strategy: strategy)
  end

  let!(:course_ecosystem) { AddEcosystemToCourse[course: course, ecosystem: ecosystem] }

  context '#prevalidate' do
    context 'anonymous user' do
      it 'returns the period and course when the code/book combo is valid' do
        response = api_post :prevalidate, nil, raw_post_data: {
                              enrollment_code: period.enrollment_code, book_uuid: book.uuid
                            }
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash.deep_stringify_keys).to(
          eq Api::V1::Enrollment::PeriodWithCourseRepresenter.new(period).as_json
        )
      end

      it 'returns an error code when the code does not exist' do
        response = api_post :prevalidate, nil, raw_post_data: {
                              enrollment_code: 'invalid-code', book_uuid: book.uuid
                            }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
      end

      it 'returns an error code when the course has ended' do
        course.update_attribute :ends_at, Time.current.yesterday
        response = api_post :prevalidate, nil, raw_post_data: {
                              enrollment_code: period.enrollment_code, book_uuid: book.uuid
                            }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'course_ended'
      end

      it 'returns an error code when the code/book combo is not valid' do
        response = api_post :prevalidate, nil, raw_post_data: {
                              enrollment_code: period.enrollment_code, book_uuid: 'invalid-uuid'
                            }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to(
          eq 'enrollment_code_does_not_match_book'
        )
      end
    end

  end

  context '#create' do
    context 'anonymous user' do
      it 'raises a SecurityTransgression' do
        expect do
          api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_uuid: book.uuid
          }.to_json
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'signed in user' do
      before(:each) { controller.sign_in user }

      context 'book_uuid given' do
        it 'creates the EnrollmentChange if there are no errors for a new student' do
          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if there are no errors for an existing student' do
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if the user has multiple student roles in the course' do
          AddUserAsCourseTeacher[user: user, course: course]
          AddUserAsPeriodStudent[user: user, period: period]
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns an error if the enrollment code is invalid' do
          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: SecureRandom.hex, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the course has ended' do
          course.update_attribute :ends_at, Time.current.yesterday
          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'course_ended'
        end

        it 'returns an error if the book_uuid does not match the course\'s book' do
          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: SecureRandom.hex
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to(
            eq 'enrollment_code_does_not_match_book'
          )
        end

        it 'returns an error if the user is already enrolled in the given period' do
          AddUserAsPeriodStudent[user: user, period: period]

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'already_enrolled'
        end

        it 'returns an error if the user has been dropped from the course' do
          AddUserAsPeriodStudent[user: user, period: period_2].student.destroy

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'dropped_student'
        end
      end

      context 'book_uuid not given' do
        it 'creates the EnrollmentChange if there are no errors for a new student' do
          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if there are no errors for an existing student' do
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if the user has multiple student roles in the course' do
          AddUserAsCourseTeacher[user: user, course: course]
          AddUserAsPeriodStudent[user: user, period: period]
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns an error if the enrollment code is invalid' do
          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: SecureRandom.hex
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the user is already enrolled in the given period' do
          AddUserAsPeriodStudent[user: user, period: period]

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'already_enrolled'
        end

        it 'returns an error if the user has been dropped from the course' do
          AddUserAsPeriodStudent[user: user, period: period_2].student.destroy

          expect do
            api_post :create, nil, raw_post_data: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'dropped_student'
        end
      end
    end
  end

  context '#approve' do
    let(:enrollment_change) do
      CourseMembership::CreateEnrollmentChange[
        user: user, enrollment_code: period.enrollment_code, requires_enrollee_approval: true
      ]
    end

    context 'anonymous user' do
      it 'returns 403 forbidden' do
        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id }
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'unauthorized user' do
      before(:each) { controller.sign_in user_2 }

      it 'returns 403 forbidden' do
        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id }
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'authorized user' do
      before(:each) { controller.sign_in user }

      it 'approves a pending EnrollmentChange request' do
        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id }
        end.to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'processes an approved EnrollmentChange request' do
        enrollment_change.to_model.approve_by(user).save!

        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id }
        end.to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'sets the student_identifier, if given, even if it is already taken' do
        sid = 'N0B0DY'
        AddUserAsPeriodStudent[user: user_2, period: period, student_identifier: sid]

        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id },
                                 raw_post_data: { student_identifier: sid }
        end.to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)

        enrollment = CourseMembership::Models::Enrollment.order(:created_at).last
        expect(enrollment.student.student_identifier).to eq sid
      end

      it 'returns an error if the EnrollmentChange request has already been rejected' do
        enrollment_change.to_model.status = :rejected
        enrollment_change.to_model.save!

        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id }
        end.not_to change{ CourseMembership::Models::Enrollment.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_rejected'
      end

      it 'returns an error if the EnrollmentChange request has already been processed' do
        enrollment_change.to_model.status = :processed
        enrollment_change.to_model.save!

        expect do
          api_put :approve, nil, parameters: { id: enrollment_change.id }
        end.not_to change{ CourseMembership::Models::Enrollment.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_processed'
      end
    end
  end
end

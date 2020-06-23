require 'rails_helper'

RSpec.describe Api::V1::EnrollmentController, type: :request, api: true, version: :v1 do
  let(:user)              { FactoryBot.create :user_profile }

  let(:user_2)            { FactoryBot.create :user_profile }

  let(:course)            { FactoryBot.create :course_profile_course, is_concept_coach: true }

  let(:period)            { FactoryBot.create :course_membership_period, course: course }
  let(:period_2)          { FactoryBot.create :course_membership_period, course: course }

  let(:book)              { FactoryBot.create :content_book }

  let(:ecosystem)         { book.ecosystem }

  let!(:course_ecosystem) { AddEcosystemToCourse[course: course, ecosystem: ecosystem] }

  context '#prevalidate' do
    context 'anonymous user' do
      it 'returns the period and course when the code/book combo is valid' do
        api_post prevalidate_api_enrollment_index_url, nil,
                 params: { enrollment_code: period.enrollment_code, book_uuid: book.uuid }.to_json
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash.deep_stringify_keys).to(
          eq Api::V1::Enrollment::PeriodWithCourseRepresenter.new(period).as_json
        )
      end

      it 'returns an error code when the code does not exist' do
        api_post prevalidate_api_enrollment_index_url, nil,
                 params: { enrollment_code: 'invalid-code', book_uuid: book.uuid }.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
      end

      it 'returns an error code when the course has ended' do
        course.update_attribute :ends_at, Time.current.yesterday
        api_post prevalidate_api_enrollment_index_url, nil,
                 params: { enrollment_code: period.enrollment_code, book_uuid: book.uuid }.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'course_ended'
      end

      it 'returns an error code when the code/book combo is not valid' do
        api_post prevalidate_api_enrollment_index_url, nil, params: {
          enrollment_code: period.enrollment_code, book_uuid: 'invalid-uuid'
        }.to_json
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
          api_post api_enrollment_index_url, nil, params: {
            enrollment_code: period.enrollment_code, book_uuid: book.uuid
          }.to_json
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'signed in user' do
      before(:each) { sign_in! user }

      context 'book_uuid given' do
        it 'creates the EnrollmentChange if there are no errors for a new student' do
          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if there are no errors for an existing student' do
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns an error if the enrollment code is invalid' do
          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: SecureRandom.hex, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the course has ended' do
          course.update_attribute :ends_at, Time.current.yesterday
          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'course_ended'
        end

        it 'returns an error if the book_uuid does not match the course\'s book' do
          expect do
            api_post api_enrollment_index_url, nil, params: {
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
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'already_enrolled'
        end

        it 'returns an error if the user has been dropped from the course' do
          AddUserAsPeriodStudent[user: user, period: period_2].student.destroy

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'dropped_student'
        end

        it 'returns an error if the user is a teacher of the course' do
          AddUserAsCourseTeacher[user: user, course: course]

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code, book_uuid: book.uuid
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'is_teacher'
          expect(response.body_as_hash[:errors].first[:data]).to eq(course_name: course.name)
        end
      end

      context 'book_uuid not given' do
        it 'creates the EnrollmentChange if there are no errors for a new student' do
          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if there are no errors for an existing student' do
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns an error if the enrollment code is invalid' do
          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: SecureRandom.hex
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the user is already enrolled in the given period' do
          AddUserAsPeriodStudent[user: user, period: period]

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'already_enrolled'
        end

        it 'returns an error if the user has been dropped from the course' do
          AddUserAsPeriodStudent[user: user, period: period_2].student.destroy

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'dropped_student'
        end

        it 'returns an error if the user is a teacher of the course' do
          AddUserAsCourseTeacher[user: user, course: course]

          expect do
            api_post api_enrollment_index_url, nil, params: {
              enrollment_code: period.enrollment_code
            }.to_json
          end.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'is_teacher'
          expect(response.body_as_hash[:errors].first[:data]).to eq(course_name: course.name)
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
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'unauthorized user' do
      before(:each) { sign_in! user_2 }

      it 'returns 403 forbidden' do
        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'authorized user' do
      before(:each) { sign_in! user }

      it 'lists periods for a course' do
        pr = period
        api_get choices_api_enrollment_url(course.uuid), nil
        expect(response.body_as_hash).to eq({
          name: course.name,
          periods: [{ name: pr.name, enrollment_code: pr.enrollment_code }]
        })
      end

      it 'approves a pending EnrollmentChange request' do
        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'processes an approved EnrollmentChange request' do
        enrollment_change.approve_by(user).save!

        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'sets the student_identifier, if given, even if it is already taken' do
        sid = 'N0B0DY'
        AddUserAsPeriodStudent[user: user_2, period: period, student_identifier: sid]

        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil,
                  params: { student_identifier: sid }.to_json
        end.to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)

        enrollment = CourseMembership::Models::Enrollment.order(:created_at).last
        expect(enrollment.student.student_identifier).to eq sid
      end

      it 'assigns published assignments to the new student' do
        FactoryBot.create :course_membership_teacher_student, period: period

        task_plan =  FactoryBot.build(:tasks_task_plan, course: course).tap do |task_plan|
          task_plan.tasking_plans.first.target = period
          task_plan.save!
        end

        # The teacher publishes an assignment, and the student doesn't get it...
        # TeacherStudent role still gets it
        expect do
          DistributeTasks.call(task_plan: task_plan)
        end.to  change     { Tasks::Models::Tasking.count }.by(1)
           .and not_change { user.roles.reload.map { |role| role.taskings.count }.sum }

        # The student signs up and they get the assignment
        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.to  change { Tasks::Models::Tasking.count }.by(1)
           .and change { user.roles.reload.map { |role| role.taskings.count }.sum }.by(1)
      end

      it 'returns an error if the EnrollmentChange request has already been rejected' do
        enrollment_change.rejected!

        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.not_to change{ CourseMembership::Models::Enrollment.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_rejected'
      end

      it 'returns an error if the EnrollmentChange request has already been processed' do
        enrollment_change.processed!

        expect do
          api_put approve_api_enrollment_url(enrollment_change.id), nil
        end.not_to change{ CourseMembership::Models::Enrollment.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_processed'
      end
    end
  end
end

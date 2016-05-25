require 'rails_helper'

RSpec.describe 'Students enrolling via URL' do
  let(:course) { CreateCourse[name: 'Biology'] }
  let(:period1) { CreatePeriod[course: course, name: '1st'] }
  let(:period2) { CreatePeriod[course: course, name: '2nd'] }

  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  context 'unauthenticated' do
    it 'redirects to login' do
      visit token_enroll_path(period1.enrollment_code_for_url)
      expect(current_path).to eq(openstax_accounts.dev_accounts_path)
    end
  end

  context 'authenticated' do
    before { stub_current_user(user) }

    context 'valid enrollment code' do

      context 'when not yet a student' do

        it 'works when student ID is supplied' do
          visit token_enroll_path(period1.enrollment_code_for_url)
          expect(page).to have_content('school-issued')

          fill_in 'enroll_student_id', with: '12345'
          click_button 'Enroll'

          expect(UserIsCourseStudent[course: course, user: user]).to be_truthy
          expect(CourseMembership::Models::Enrollment.last.period).to eq period1.to_model
          expect(current_path).to eq(course_dashboard_path(course))
          expect(CourseMembership::Models::Student.last.student_identifier).to eq '12345'
        end

        it 'works when student ID is NOT supplied' do
          visit token_enroll_path(period1.enrollment_code_for_url)
          expect(page).to have_content('school-issued')

          click_button 'Enroll'

          expect(UserIsCourseStudent[course: course, user: user]).to be_truthy
          expect(CourseMembership::Models::Enrollment.last.period).to eq period1.to_model
          expect(current_path).to eq(course_dashboard_path(course))
          expect(CourseMembership::Models::Student.last.student_identifier).to be_nil
        end

        it 'errors when a student ID is already used' do
          AddUserAsPeriodStudent[period: period1, user: other_user, student_identifier: 'abc']

          visit token_enroll_path(period1.enrollment_code_for_url)
          expect(page).to have_content('school-issued')

          fill_in 'enroll_student_id', with: 'abc'
          click_button 'Enroll'

          expect(page).to have_content 'is already in use'
          expect(page).to have_content 'Enter your school-issued'
          expect(UserIsCourseStudent[course: course, user: user]).to be_falsy
        end

      end

      context 'when already a student of targeted period' do
        before { AddUserAsPeriodStudent[user: user, period: period1] }

        it 'drops straight into course' do
          visit token_enroll_path(period1.enrollment_code_for_url)
          expect(current_path).to eq(course_dashboard_path(course))
          expect(page.body).to have_content "notice\":\"You are already enrolled"
        end
      end

      context 'when already a student of a different period same course' do
        it 'drops the user straight into the course' do
          AddUserAsPeriodStudent[period: period2, user: user]
          visit token_enroll_path(period1.enrollment_code_for_url)
          expect(current_path).to eq(course_dashboard_path(course))
        end
      end

    end

    context 'invalid enrollment code' do
      it 'renders an error page' do
        rescuing_exceptions do
          visit token_enroll_path('invalid-no-way-it-will-work')
        end

        expect(page).to have_content 'You are trying to enroll in a class as a student'
      end
    end
  end

end

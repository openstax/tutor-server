require 'rails_helper'

RSpec.feature 'Teachers' do
  let(:course) { FactoryGirl.create :course_profile_course }
  let(:user)   { FactoryGirl.create(:user) }

  before(:each) { page.driver.header('User-Agent', chrome_ua) }

  context 'joining their courses' do

    context 'unauthenticated' do
      scenario 'redirects to login' do
        visit teach_course_path(course.teach_token)
        expect(current_path).to eq(openstax_accounts.dev_accounts_path)
      end
    end

    context 'authenticated' do
      before { stub_current_user(user) }

      context 'valid join token' do
        before { visit teach_course_path(course.teach_token) }

        scenario 'adds the user as the teacher' do
          expect(UserIsCourseTeacher[course: course, user: user]).to be true
        end

        scenario 'redirects the user to the course page' do
          expect(current_path).to eq(course_dashboard_path(course))
        end
      end

      context 'already added as a teacher' do
        scenario 'redirects them to the course page' do
          rescuing_exceptions do
            visit teach_course_path(course.teach_token)
            visit teach_course_path(course.teach_token)
          end

          expect(current_path).to eq(course_dashboard_path(course))
        end
      end

      context 'invalid join token' do
        scenario 'renders an error page' do
          rescuing_exceptions do
            visit teach_course_path('invalid-no-way-it-will-work')
          end

          expect(page).to have_css(
            '.rescue-from',
             text: 'You are trying to join a course as an instructor, but the information you ' +
                   'provided is either out of date or does not correspond to an existing course.'
          )
        end
      end
    end
  end
end

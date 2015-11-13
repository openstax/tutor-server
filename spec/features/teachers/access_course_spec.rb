require 'rails_helper'

RSpec.describe 'Teachers' do
  let(:course) { CreateCourse[name: 'Access me'] }
  let(:user) { FactoryGirl.create(:user) }

  describe 'joining their courses' do
    context 'unauthenticated' do
      it 'redirects to login' do
        visit join_course_path(course.teacher_join_token)
        expect(current_path).to eq(openstax_accounts.dev_accounts_path)
      end
    end

    context 'authenticated' do
      before { stub_current_user(user) }

      context 'valid join token' do
        before { visit join_course_path(course.teacher_join_token) }

        it 'adds the user as the teacher' do
          expect(UserIsCourseTeacher[course: course, user: user]).to be true
        end

        it 'redirects the user to the dashboard' do
          expect(current_path).to eq(dashboard_path)
        end
      end

      context 'already added as a teacher' do
        it 'renders an error page' do
          rescuing_exceptions do
            visit join_course_path(course.teacher_join_token)
            visit join_course_path(course.teacher_join_token)
          end

          expect(page).to have_css('.rescue-from',
                                   text: 'You are already a teacher of this course.')
        end
      end

      context 'invalid join token' do
        it 'renders an error page' do
          rescuing_exceptions do
            visit join_course_path('invalid-no-way-it-will-work')
          end

          expect(page).to have_css('.rescue-from',
                                   text: 'You are trying to join a class as a teacher, but the information you provided is either out of date or does not correspond to an existing course.')
        end
      end
    end
  end
end

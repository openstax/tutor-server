require 'rails_helper'

RSpec.describe CoursesController, type: :controller do
  let(:user)   { FactoryBot.create :user }
  let(:course) { FactoryBot.create :course_profile_course }

  context '#teach' do
    let(:teach_token) { course.teach_token }
    subject(:action)  { get :teach, params: { teach_token: teach_token } }

    context 'signed in user' do
      before { controller.sign_in(user) }

      it 'calls CoursesTeach and redirects to the course dashboard' do
        handle = CoursesTeach.method :handle

        expect(CoursesTeach).to receive(:handle) do |args|
          expect(args[:caller]).to eq user
          expect(args[:params][:teach_token]).to eq teach_token
          handle.call args
        end

        action

        expect(response).to redirect_to(course_dashboard_path(course.id))
      end
    end

    context 'anonymous user' do
      it 'redirects to the login page' do
        expect(CoursesTeach).not_to receive(:handle)

        action

        expect(response).to redirect_to(controller.openstax_accounts.login_path)
      end
    end
  end
end

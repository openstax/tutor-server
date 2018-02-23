require 'rails_helper'

RSpec.describe Api::V1::UpdatesController, type: :controller, api: true, version: :v1 do

  let(:course)           { FactoryBot.create :course_profile_course }

  let(:instructor_user)  { FactoryBot.create(:user) }
  let!(:instructor_role) { AddUserAsCourseTeacher[user: instructor_user, course: course] }
  let(:instructor_token) do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: instructor_user.id
  end

  context '#index' do

    before do
      3.times { |num| Settings::Notifications.add(:general, "General message #{num + 1}") }
      3.times { |num| Settings::Notifications.add(:instructor, "Instructor message #{num + 1}") }
    end

    after  do
      [:general, :instructor].each do |type|
        Settings::Notifications.all(type: type).each do |notification|
          Settings::Notifications.remove(type: type, id: notification.id)
        end
      end
    end

    let(:general_notifications)         { Settings::Notifications.active(:general)    }
    let(:instructor_notifications)      { Settings::Notifications.active(:instructor) }

    let(:general_notifications_hash)    do
      general_notifications.map do |notification|
        { type: 'general', id: notification.id, message: notification.message }
      end
    end
    let(:instructor_notifications_hash) do
      instructor_notifications.map do |notification|
        { type: 'instructor', id: notification.id, message: notification.message }
      end
    end

    context 'any non-instructor user' do
      it 'returns the contents of the general notifications' do
        api_get :index, nil
        expect(response.body_as_hash[:notifications]).to match_array general_notifications_hash
      end
    end

    context 'instructor user' do
      it 'returns the contents of the general notifications' do
        api_get :index, instructor_token
        expect(response.body_as_hash[:notifications]).to(
          match_array instructor_notifications_hash + general_notifications_hash
        )
      end

    end

    it 'includes the payment status' do
      api_get :index, nil
      expect(response.body_as_hash[:payments]).to eq(is_enabled: Settings::Payments.payments_enabled)
    end

  end

end

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  subject(:controller) do
    ApplicationController.new.tap { |cc| cc.response = ActionController::TestResponse.new }
  end

  before(:all) do
    @timecop_enable = Rails.application.secrets[:timecop_enable]
  end

  after(:all) do
    Rails.application.secrets[:timecop_enable] = @timecop_enable
  end

  context 'with timecop enabled' do
    before(:all) do
      Rails.application.secrets[:timecop_enable] = true
    end

    it 'travels time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t + 1.hour)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t - 1.hour)

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)
    end

    it 'sets the X-App-Date header to the timecop time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t + 1.hour)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t - 1.hour)

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)
    end
  end

  context 'with timecop disabled' do
    before(:all) do
      Rails.application.secrets[:timecop_enable] = false
    end

    it 'does not travel time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)
    end

    it 'sets the X-App-Date header to the actual time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)
    end
  end

  context '#current_role' do
    let(:teacher_student)       { FactoryBot.create :course_membership_teacher_student }
    let(:course)                { teacher_student.course }
    let!(:teacher_student_role) { teacher_student.role }
    let(:user)                  { teacher_student_role.profile }
    let!(:teacher_role)         { AddUserAsCourseTeacher[user: user, course: course] }
    let!(:another_teacher_role) do
      FactoryBot.create(:course_membership_teacher, course: course).role
    end

    before do
      allow(controller).to receive(:session).and_return({})
      allow(controller).to receive(:current_user).and_return(user)
    end

    it "can return the user's current role for a given course" do
      expect(controller.send :current_role, course).to be_nil

      controller.session[:roles] = { course.id.to_s => teacher_role.id }
      expect(controller.send :current_role, course).to eq teacher_role

      controller.session[:roles] = { course.id.to_s => teacher_student_role.id }
      expect(controller.send :current_role, course).to eq teacher_student_role
    end

    it 'does not return roles belonging to other users or invalid roles' do
      expect(controller.send :current_role, course).to be_nil

      controller.session[:roles] = { course.id.to_s => another_teacher_role.id }
      expect(controller.send :current_role, course).to be_nil

      controller.session[:roles] = { course.id.to_s => 'abc' }
      expect(controller.send :current_role, course).to be_nil
    end
  end
end

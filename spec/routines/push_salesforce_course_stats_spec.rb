require 'rails_helper'

RSpec.describe PushSalesforceCourseStats, type: :routine do

  context "#best_sf_contact_id_for_course" do
    let(:course)        { FactoryGirl.create :course_profile_course }
    let(:user_no_sf)    { FactoryGirl.create(:user) }
    let(:user_sf_a)     { FactoryGirl.create(:user, salesforce_contact_id: 'a') }
    let(:user_sf_b)     { FactoryGirl.create(:user, salesforce_contact_id: 'b') }

    subject { instance.best_sf_contact_id_for_course(course) }

    it 'returns nil if there are no teachers' do
      expect(subject).to be_nil
    end

    it 'returns nil if there are no teachers with a SF contact ID' do
      AddUserAsCourseTeacher[course: course, user: user_no_sf]
      expect(subject).to be_nil
    end

    it 'returns the SF ID when there is one teacher with a SF ID' do
      AddUserAsCourseTeacher[course: course, user: user_sf_b]
      expect(subject).to eq "b"
    end

    context "order matters when multiple teachers" do
      it 'returns "b" when "b" added first' do
        AddUserAsCourseTeacher[course: course, user: user_sf_b]
        AddUserAsCourseTeacher[course: course, user: user_sf_a]
        expect(subject).to eq "b"
      end

      it 'returns "a" when "a" added first' do
        AddUserAsCourseTeacher[course: course, user: user_sf_a]
        AddUserAsCourseTeacher[course: course, user: user_sf_b]
        expect(subject).to eq "a"
      end
    end
  end

  context "#applicable_courses" do
    it 'limits by created_at' do
      Timecop.travel(Chronic.parse("12/25/2016")) do
        2.times { FactoryGirl.create :course_profile_course }
      end

      after_courses = Timecop.travel(Chronic.parse("12/27/2016")) do
        2.times.map { FactoryGirl.create :course_profile_course }
      end

      expect(instance.applicable_courses).to eq after_courses
    end
  end

  context "#salesforce_term_year_for_course" do
    subject {
      course = FactoryGirl.create :course_profile_course, term: @term, year: @year
      instance.salesforce_term_year_for_course(course)
    }

    it 'works for fall terms' do
      @term = :fall; @year = 2018
      expect(subject).to eq "2018 - 19 Fall"
    end

    it 'works for spring terms' do
      @term = :spring; @year = 2018
      expect(subject).to eq "2017 - 18 Spring"
    end

    it 'errors for legacy terms' do
      @term = :legacy; @year = 2015
      expect(subject).to raise_error(IllegalState)
    end

    it 'errors for summer terms b/c SF does not yet support' do
      @term = :summer; @year = 2015
      expect(subject).to raise_error(IllegalState)
    end
  end

  context "#notify_errors" do
    it 'does nothing if no errors' do
      expect(Rails.logger).not_to receive(:warn)
      run_notify_errors
    end

    context "when error email allowed" do
      before(:each) { expect(Rails.logger).to receive(:warn) }

      it 'logs but does not email if not real production' do
        real_production!(false)
        expect(DevMailer).not_to receive(:inspect_object)
        run_notify_errors('yo')
      end

      it 'logs and emails if real production' do
        real_production!(true)
        expect{
          run_notify_errors('yo')
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    def run_notify_errors(message = nil)
      @instance = instance
      @instance.error!(message: message) if message.present?
      @instance.notify_errors
    end
  end

  def instance
    described_class.new(allow_error_email: true)
  end

  def real_production!(true_or_false)
    allow_any_instance_of(described_class).to receive(:is_real_production?) { true_or_false }
  end

end

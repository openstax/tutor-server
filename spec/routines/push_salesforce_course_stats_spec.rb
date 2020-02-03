require 'rails_helper'

RSpec.describe PushSalesforceCourseStats, type: :routine, speed: :slow do
  subject(:instance) { described_class.new }

  context "#best_sf_contact_id_for_course" do
    let(:course)        { FactoryBot.create :course_profile_course }
    let(:user_no_sf)    { FactoryBot.create(:user_profile) }
    let(:user_sf_a)     { FactoryBot.create(:user_profile, salesforce_contact_id: 'a') }
    let(:user_sf_b)     { FactoryBot.create(:user_profile, salesforce_contact_id: 'b') }

    subject { instance.best_sf_contact_id_for_course(course) }

    it 'errors if there are no teachers' do
      expect{ subject }.to throw_symbol(:go_to_next_record)
    end

    it 'returns nil if there are no teachers with a SF contact ID' do
      AddUserAsCourseTeacher[course: course, user: user_no_sf]
      expect{ subject }.to throw_symbol(:go_to_next_record)
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

  context "#base_year_for_course" do
    let(:course) { FactoryBot.create :course_profile_course, term: @term, year: @year }
    subject { instance.base_year_for_course(course) }

    it "gives 2016 for Fall 2016" do
      @term = :fall
      @year = 2016
      is_expected.to eq 2016
    end

    it "gives 2016 for Winter 2017" do
      @term = :winter
      @year = 2017
      is_expected.to eq 2016
    end

    it "gives 2016 for Spring 2017" do
      @term = :spring
      @year = 2017
      is_expected.to eq 2016
    end

    it "gives 2016 for Summer 2017" do
      @term = :summer
      @year = 2017
      is_expected.to eq 2016
    end
  end

  context "#applicable_courses" do
    it 'limits by ends_at' do
      a = FactoryBot.create(:course_profile_course, starts_at: Chronic.parse("1/1/2017"),
                                                     ends_at: Chronic.parse("6/30/2017"),
                                                     term: "spring")
      b = FactoryBot.create(:course_profile_course, starts_at: Chronic.parse("1/1/2017"),
                                                     ends_at: Chronic.parse("7/2/2017"),
                                                     term: "spring")

      Timecop.freeze(Chronic.parse("7/1/2017")) do
        expect(instance.applicable_courses).to contain_exactly(b)
      end

      Timecop.freeze(Chronic.parse("7/2/2017")) do
        expect(instance.applicable_courses).to be_empty
      end
    end

    it 'excludes excluded courses' do
      a = FactoryBot.create(:course_profile_course, consistent_times: true,
                                                     term: :fall, year: 2018,
                                                     is_excluded_from_salesforce: true)
      b = FactoryBot.create(:course_profile_course, consistent_times: true,
                                                     term: :fall, year: 2018)

      Timecop.freeze(Chronic.parse("7/1/2017")) do
        expect(instance.applicable_courses).to contain_exactly(b)
      end
    end

    it 'excludes test courses' do
      a = FactoryBot.create(:course_profile_course, consistent_times: true,
                                                     term: :fall, year: 2018,
                                                     is_test: true)
      b = FactoryBot.create(:course_profile_course, consistent_times: true,
                                                     term: :fall, year: 2018)

      Timecop.freeze(Chronic.parse("7/1/2017")) do
        expect(instance.applicable_courses).to contain_exactly(b)
      end
    end
  end

  context "#notify_errors" do
    it 'does nothing if no errors' do
      expect(Rails.logger).not_to receive(:error)
      expect(Raven).not_to receive(:capture_exception)
      expect(Raven).not_to receive(:capture_message)
      run_notify_errors
    end

    { exception: RuntimeError.new, message: 'yo' }.each do |key, value|
      context key.to_s do
        let(:raven_method) { "capture_#{key}".to_sym }

        it 'logs the error to the console and to Sentry' do
          expect(Rails.logger).to receive(:error)
          expect(Raven).to receive(raven_method) { |first_arg, *| expect(first_arg).to eq value }
          catch(:go_to_next_record) { instance.error!(key => value) }
          expect { run_notify_errors }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    it 'throws go_to_next_record' do
      expect { run_notify_errors('yo') }.to throw_symbol(:go_to_next_record)
    end

    def run_notify_errors(message = nil)
      instance.error!(message: message) if message.present?
      instance.notify_errors
    end
  end
end

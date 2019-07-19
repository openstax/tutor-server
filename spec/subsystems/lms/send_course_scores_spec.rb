require 'rails_helper'

RSpec.describe Lms::SendCourseScores, type: :routine do
  before(:all) do
    period = FactoryBot.create :course_membership_period
    @course = period.course
    @course.lms_contexts << FactoryBot.create(:lms_context, course: @course)
    callback = FactoryBot.create :lms_course_score_callback, course: @course
    student = callback.profile
    AddUserAsPeriodStudent[period: period, user: student]

    FactoryBot.create :tasked_task_plan, owner: @course

    teacher = FactoryBot.create :user_profile
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: teacher]
  end

  subject(:instance) { described_class.new }

  it 'calls Tasks::GetPerformanceReport to get the report information' do
    expect(Tasks::GetPerformanceReport).to(
      receive(:[]).with(course: @course, is_teacher: true).once.and_call_original
    )

    expect { described_class.call(course: @course) }.not_to raise_error
  end

  it 'does not have blank space before the XML declaration' do
    # such blank space is not allowed and some LMSes flip out
    expect(instance.basic_outcome_xml(score: 0.5, sourcedid: 'hi')[0]).not_to match(/\s/)
  end

  it 'uses willo key/secret for courses that are using it' do
    expect(OAuth::Consumer).to receive(:new).with(
                                 Lms::WilloLabs.config[:key],
                                 Lms::WilloLabs.config[:secret])

    @course.lms_contexts.first.update_attributes! app_type: 'Lms::WilloLabs'
    described_class.call(course: @course)
  end

  context "#notify_errors" do
    before { instance.instance_variable_set '@errors', [] }

    it 'does nothing if no errors' do
      expect(Rails.logger).not_to receive(:error)
      expect(Raven).not_to receive(:capture_exception)
      expect(Raven).not_to receive(:capture_message)
      instance.notify_errors
    end

    { exception: RuntimeError.new, message: 'yo' }.each do |key, value|
      context key.to_s do
        let(:raven_method) { "capture_#{key}".to_sym }

        it 'logs the error to the console and to Sentry' do
          expect(Rails.logger).to receive(:error)
          expect(Raven).to receive(raven_method) { |first_arg, *| expect(first_arg).to eq value }
          instance.error!(key => value)
          expect { instance.notify_errors }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Lms::SendCourseScores, type: :routine do
  before(:all) do
    period = FactoryBot.create :course_membership_period
    @course = period.course
    @course.lms_contexts << FactoryBot.create(:lms_context, course: @course)
    callback = FactoryBot.create :lms_course_score_callback, course: @course
    student_user = callback.profile
    @student_role = AddUserAsPeriodStudent[period: period, user: student_user]

    FactoryBot.create :tasked_task_plan, course: @course, number_of_students: 0

    teacher_user = FactoryBot.create :user_profile
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: teacher_user]
  end

  subject(:instance) { described_class.new }

  before { @course.reload }

  it 'calls Tasks::GetPerformanceReport to get the report information' do
    expect(Tasks::GetPerformanceReport).to(
      receive(:[]).with(course: @course, is_teacher: true).once.and_call_original
    )

    expect { described_class.call(course: @course) }.not_to raise_error
  end

  it 'errors if the course was created in a different environment' do
    expect(Tasks::GetPerformanceReport).not_to receive(:[])

    @course.update_attribute :environment, FactoryBot.create(:environment)

    expect { described_class.call(course: @course) }.to(
      raise_error 'This course was created in a different environment'
    )
  end

  it 'does not have blank space before the XML declaration' do
    # such blank space is not allowed and some LMSes flip out
    expect(instance.basic_outcome_xml(score: 0.5, sourcedid: 'hi')[0]).not_to match(/\s/)
  end

  context 'numeric score for a known user' do
    before do
      expect_any_instance_of(described_class).to(
        receive(:course_score_data).and_return(course_average: 0.84)
      )
    end

    it 'sends the score' do
      expect_any_instance_of(described_class).to receive :send_one_score
      expect_any_instance_of(described_class).to receive :save_status_data

      described_class.call course: @course
    end

    it 'uses WilloLabs key/secret for courses that are using them' do
      expect(OAuth::Consumer).to(
        receive(:new).with(Lms::WilloLabs.config[:key], Lms::WilloLabs.config[:secret])
      )

      @course.lms_contexts.first.update_attributes! app_type: 'Lms::WilloLabs'
      described_class.call course: @course
    end
  end

  context 'dropped student' do
    before do
      @student_role.student.destroy
      expect_any_instance_of(described_class).not_to receive(:course_score_data)
    end

    it 'does not send a score' do
      expect_any_instance_of(described_class).not_to receive :send_one_score
      expect_any_instance_of(described_class).to receive(:save_status_data)

      described_class.call course: @course
    end
  end

  context 'unknown user' do
    before { expect_any_instance_of(described_class).to receive :course_score_data }

    it 'does not send a score' do
      expect_any_instance_of(described_class).not_to receive :send_one_score
      expect_any_instance_of(described_class).to receive(:save_status_data).twice

      described_class.call course: @course
    end
  end

  context 'known user with no course_average' do
    before do
      expect_any_instance_of(described_class).to(
        receive(:course_score_data).and_return(course_average: nil)
      )
    end

    it 'does not send the null score' do
      expect_any_instance_of(described_class).not_to receive :send_one_score
      expect_any_instance_of(described_class).to receive(:save_status_data).twice

      described_class.call course: @course
    end
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
          instance.notify_errors
        end
      end
    end
  end
end

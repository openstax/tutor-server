require 'rails_helper'

RSpec.describe Lms::SendCourseScores, type: :routine do

  before(:all) do
    period = FactoryBot.create :course_membership_period
    @course = period.course
    @course.lms_context = FactoryBot.create(:lms_context, course: @course)
    callback = FactoryBot.create :lms_course_score_callback, course: @course
    student = callback.profile
    AddUserAsPeriodStudent[period: period, user: student]

    task_plan = FactoryBot.create :tasked_task_plan, owner: @course

    teacher = FactoryBot.create :user_profile
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: teacher]
  end

  it 'calls Tasks::GetTpPerformanceReport to get the report information' do
    expect(Tasks::GetTpPerformanceReport).to(
      receive(:[]).with(course: @course, is_teacher: true).once.and_call_original
    )

    expect { described_class.call(course: @course) }.not_to raise_error
  end

  it 'does not have blank space before the XML declaration' do
    # such blank space is not allowed and some LMSes flip out
    expect(described_class.new.basic_outcome_xml(score: 0.5, sourcedid: 'hi')[0]).not_to match(/\s/)
  end

  it 'uses willo key/secret for courses that are using it' do
    expect(OAuth::Consumer).to receive(:new).with(
                                 Lms::WilloLabs.config['key'],
                                 Lms::WilloLabs.config['secret'])

    @course.lms_context.update_attributes app_type: 'Lms::WilloLabs'
    described_class.call(course: @course)
  end
end

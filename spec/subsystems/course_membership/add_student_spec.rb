require 'rails_helper'

RSpec.describe CourseMembership::AddStudent, type: :routine do
  context "when adding a new student role to a period" do
    let(:role) { FactoryGirl.create :entity_role }
    let(:course) { FactoryGirl.create :course_profile_course }
    let(:period) { FactoryGirl.create :course_membership_period, course: course }

    it "succeeds" do
      result = nil
      expect {
        result = CourseMembership::AddStudent.call(period: period, role: role)
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
      expect(course.reload.is_access_switchable).to eq false
    end

    it 'sets the payment_due_at to midnight of appropriate day' do
      # Freeze at a time where the due date will cross into daylight savings time
      Timecop.freeze(Chronic.parse("March 9, 2017 5:04pm")) do
        result = CourseMembership::AddStudent.call(period: period, role: role)
        student = result.outputs.student
        grace_days = Settings::Payments.student_grace_period_days

        expect(student.payment_due_at - Time.now).to be_within(1.day).of(Settings::Payments.student_grace_period_days.days)
        expect(student.payment_due_at.in_time_zone(course.time_zone.to_tz).to_s).to include("23:59:59")
      end
    end

    it "allows a student_identifier to be specified" do
      sid = 'N0B0DY'

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(period: period, role: role,
                                                   student_identifier: sid)
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs.student.student_identifier).to eq sid
    end
  end

  context "when adding an existing student role to a course" do
    it "fails" do
      role     = FactoryGirl.create :entity_role
      course   = FactoryGirl.create :course_profile_course
      period_1 = FactoryGirl.create :course_membership_period, course: course
      period_2 = FactoryGirl.create :course_membership_period, course: course

      result = nil
      expect {
        result = CourseMembership::AddStudent.call(period: period_1, role: role)
      }.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
      student = CourseMembership::Models::Student.order(:created_at).last
      expect(student.course).to eq course
      expect(student.period.id).to eq period_1.id

      expect {
        result = CourseMembership::AddStudent.call(period: period_2, role: role)
      }.to_not change{ CourseMembership::Models::Student.count }
      expect(result.errors).to_not be_empty
      expect(student.reload.course).to eq course
      expect(student.period.id).to eq period_1.id
    end
  end
end

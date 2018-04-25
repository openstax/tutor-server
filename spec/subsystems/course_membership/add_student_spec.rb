require 'rails_helper'

RSpec.describe CourseMembership::AddStudent, type: :routine do
  context "when adding a new student role to a period" do
    let(:role)   { FactoryBot.create :entity_role }
    let(:course) { FactoryBot.create :course_profile_course }
    let(:period) { FactoryBot.create :course_membership_period, course: course }

    it "succeeds" do
      result = nil
      expect do
        result = CourseMembership::AddStudent.call(period: period, role: role)
      end.to change{ CourseMembership::Models::Student.count }.by(1)
      expect(result.errors).to be_empty
      expect(course.reload.is_access_switchable).to eq false
    end

    it 'sets the payment_due_at to midnight of appropriate day' do
      # Freeze at a time where the due date will cross into daylight savings time
      Timecop.freeze(Chronic.parse("March 9, 2017 5:04pm")) do
        result = CourseMembership::AddStudent.call(period: period, role: role)
        student = result.outputs.student
        grace_days = Settings::Payments.student_grace_period_days

        expect(student.payment_due_at - Time.now).to(
          be_within(1.day).of(Settings::Payments.student_grace_period_days.days)
        )
        expect(student.payment_due_at.in_time_zone(course.time_zone.to_tz).to_s).to(
          include("23:59:59")
        )
      end
    end

    it 'extends the payment_due_at when the course hasn\'t started yet' do
      # Freeze at a time where the due date will cross into daylight savings time
      Timecop.freeze(Chronic.parse("March 2, 2017 5:04pm")) do
        course.update_attribute :starts_at, Time.now + 1.week
        result = CourseMembership::AddStudent.call(period: period, role: role)
        student = result.outputs.student
        grace_days = Settings::Payments.student_grace_period_days

        expect(student.payment_due_at - course.starts_at).to(
          be_within(1.day).of(Settings::Payments.student_grace_period_days.days)
        )
        expect(student.payment_due_at.in_time_zone(course.time_zone.to_tz).to_s).to(
          include("23:59:59")
        )
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

    it "assigns any published surveys" do
      study = FactoryBot.create :research_study
      Research::AddCourseToStudy[course: course, study: study]
      survey_plan = FactoryBot.create :research_survey_plan, :published, study: study

      student = described_class[period: period, role: role]
      expect(student.surveys.map(&:research_survey_plan_id)).to eq [survey_plan.id]
    end
  end

  context "when adding an existing student role to a course" do
    it "fails" do
      role     = FactoryBot.create :entity_role
      course   = FactoryBot.create :course_profile_course
      period_1 = FactoryBot.create :course_membership_period, course: course
      period_2 = FactoryBot.create :course_membership_period, course: course

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

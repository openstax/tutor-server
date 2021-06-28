require 'rails_helper'

RSpec.describe Admin::PaymentsController, type: :request do
  let(:admin)  { FactoryBot.create(:user_profile, :administrator) }
  before       { sign_in! admin }

  context 'extend payment due dates' do
    it 'only applies to students in unended courses' do
      old_student = nil
      Timecop.travel(1.year.ago) do
        old_course = FactoryBot.create :course_profile_course
        old_period = FactoryBot.create :course_membership_period, course: old_course
        old_student = AddUserAsPeriodStudent[user: FactoryBot.create(:user_profile), period: old_period].student
      end

      current_course = FactoryBot.create :course_profile_course
      current_period = FactoryBot.create :course_membership_period, course: current_course
      current_student = AddUserAsPeriodStudent[
        user: FactoryBot.create(:user_profile), period: current_period
      ].student

      Timecop.travel(1.month.from_now) do
        original_old_student_payment_due_at = old_student.payment_due_at
        original_current_student_payment_due_at = current_student.payment_due_at

        put extend_payment_due_at_admin_payments_url

        old_student.reload
        current_student.reload

        expect(old_student.payment_due_at).to eq original_old_student_payment_due_at
        expect(current_student.payment_due_at).not_to eq original_current_student_payment_due_at
        expect(current_student.payment_due_at - Time.now).to be_within(1.1.day).of(Settings::Payments.student_grace_period_days.days)
      end
    end
  end

  context 'generating payment codes' do
    it 'downloads a CSV file' do
      expect {
         post generate_payment_codes_admin_payments_path, params: { prefix: 'abc', amount: 20 }
      }.to change { PaymentCode.count }.by 20

      expect(response.body).to match('Code')
    end

    it 'downloads a report' do
      get download_payment_code_report_admin_payments_path
      expect(response.body).to match('Code')
    end
  end
end

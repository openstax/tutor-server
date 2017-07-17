require "rails_helper"

RSpec.describe Api::V1::PurchasesController, type: :controller, api: true, version: :v1 do

  let(:application)       { FactoryGirl.create :doorkeeper_application }

  let(:period)            { FactoryGirl.create :course_membership_period }

  let(:student_user)      { FactoryGirl.create(:user) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }
  let(:student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:other_user)        { FactoryGirl.create(:user) }
  let(:other_user_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: other_user.id }

  describe "#check" do
    it 'gives accepted status when the student exists' do
      student = FactoryGirl.create(:course_membership_student)
      expect(UpdatePaymentStatus).to receive(:perform_later).with(uuid: student.uuid)
      api_put :check, nil, parameters: { id: student.uuid }
      expect(response).to have_http_status(:accepted)
    end

    it 'gives not found status when the student does not exist' do
      api_put :check, nil, parameters: { id: 'some UUID' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "#refund" do
    it "gives not found status when the student does not exist" do
      api_put :refund, student_token, parameters: { id: 'some UUID' }
      expect(response).to have_http_status(:not_found)
    end

    it "gives 403 when user does not own student" do
      expect{
        api_put :refund, other_user_token, parameters: { id: student.uuid }
      }.to raise_error(SecurityTransgression)
    end

    it "gives 422 not paid if not paid" do
      api_put :refund, student_token, parameters: { id: student.uuid }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors]).to match a_collection_containing_exactly(
        a_hash_including(code: 'not_paid')
      )
    end

    it "gives 422 if paid too long ago" do
      Timecop.freeze(Time.now - 14.days) do
        student.update_attributes!(is_paid: true)
      end
      api_put :refund, student_token, parameters: { id: student.uuid }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors]).to match a_collection_containing_exactly(
        a_hash_including(code: 'refund_period_elapsed')
      )
    end

    it "gives 202 accepted if all good" do
      student.update_attributes!(is_paid: true)
      expect(RefundPayment).to receive(:perform_later).with(uuid: student.uuid)
      api_put :refund, student_token, parameters: { id: student.uuid }
      expect(response).to have_http_status(:accepted)
    end
  end

  describe "#index" do
    # meaningful tests of this need VCR, so let's keep those tests in the
    # /spec/requests/api/v1/purchases_spec.rb and leave non-VCR logic tests in
    # this spec.
  end

  describe "#create_fake" do
    it 'creates new fake purchased items' do
      uuids = 2.times.map{ SecureRandom.uuid }
      api_post :create_fake, nil, raw_post_data: uuids.to_json
      expect(OpenStax::Payments::FakePurchasedItem.find(uuids[0])).to be_present
      expect(OpenStax::Payments::FakePurchasedItem.find(uuids[1])).to be_present
    end
  end

end

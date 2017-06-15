require "rails_helper"

RSpec.describe Api::V1::PurchasesController, type: :controller, api: true, version: :v1 do

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

  describe "#create_fake" do
    it 'creates new fake purchased items' do
      uuids = 2.times.map{ SecureRandom.uuid }
      api_post :create_fake, nil, raw_post_data: uuids.to_json
      expect(OpenStax::Payments::FakePurchasedItem.find(uuids[0])).to be_present
      expect(OpenStax::Payments::FakePurchasedItem.find(uuids[1])).to be_present
    end
  end

end

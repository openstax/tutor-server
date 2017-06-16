require "rails_helper"

RSpec.describe Api::V1::PurchasesController, type: :controller, api: true, version: :v1 do

  describe "#check" do
    it 'gives accepted status when the student exists' do
      allow(CourseMembership::Models::Student).to receive(:find_by) { CourseMembership::Models::Student.new }
      api_put :check, nil, parameters: { id: 'some UUID' }
      expect(response).to have_http_status(:accepted)
    end

    it 'gives not found status when the student does not exist' do
      api_put :check, nil, parameters: { id: 'some UUID' }
      expect(response).to have_http_status(:not_found)
    end
  end

end

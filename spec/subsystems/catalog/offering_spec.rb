require 'rails_helper'

RSpec.describe Catalog::Offering, type: :model do

  let(:offering) { FactoryGirl.create :catalog_offering }
  let(:wrapper)  { described_class.new(strategy: offering) }

  it 'proxies to object' do
    [:id, :salesforce_book_name, :appearance_code, :is_tutor, :is_concept_coach,
     :is_available, :title, :description, :webview_url, :pdf_url].each do | attr |
      expect(wrapper.send(attr)).to eq offering.send(attr)
    end
  end

end

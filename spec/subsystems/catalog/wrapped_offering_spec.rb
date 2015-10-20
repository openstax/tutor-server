require 'rails_helper'

RSpec.describe Catalog::Offering do

  let(:offering){ FactoryGirl.create :catalog_offering }
  let(:wrapper){ Catalog::Offering.new(strategy: offering) }

  it 'proxies to object' do
    [:id, :identifier, :is_tutor, :is_concept_coach, :description, :webview_url, :pdf_url].each do | attr |
      expect(wrapper.send(attr)).to eq offering.send(attr)
    end
  end

end

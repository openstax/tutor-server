require 'rails_helper'

RSpec.describe Settings::Pardot, type: :lib do
  it 'can store the TOA redirect' do
    expect(described_class.toa_redirect).to be_blank

    described_class.toa_redirect = "http://www.google.com"
    expect(described_class.toa_redirect).to eq "http://www.google.com"
  end
end

require 'rails_helper'

RSpec.describe Lms::WilloLabs do

  it 'reads from secrets' do
    expect(Rails.application.secrets.lms).to(
      receive(:[]).with(:willo_labs).at_least(:once).and_return(
        key: '1234key', secret: '1234secret'
      )
    )
    wl = described_class.new
    expect(wl.key).to eq '1234key'
    expect(wl.secret).to eq '1234secret'
  end

end

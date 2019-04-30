require 'rails_helper'

RSpec.describe Api::V1::UpdatesRepresenter, type: :representer do

  let(:notifications) { [] }
  let(:representation) {
    described_class.new(
      OpenStruct.new(notifications: notifications)
    )
  }

  it 'updates tutor_js_url when it changes' do
    expect(Tutor::Assets::Scripts).to receive(:[]).with(:tutor) { '/a/url' }
    expect(
      representation.to_hash
    ).to include 'tutor_js_url' => '/a/url'

    expect(Tutor::Assets::Scripts).to receive(:[]).with(:tutor) { '/a/new/url' }
    expect(
      representation.to_hash
    ).to include 'tutor_js_url' => '/a/new/url'
  end
end

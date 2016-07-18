require 'rails_helper'

RSpec.describe Api::V1::SnapLabRepresenter, type: :representer do
  let(:snap_lab) { { id: 'fs-id1164355841632',
                      page_id: 1,
                      title: 'Using Models and the Scientific Processes' } }
  subject(:represented) { described_class.new(Hashie::Mash.new(snap_lab)).to_hash }

  it 'represents a snap lab' do
    expect(represented).to eq(
      'id' => '1:fs-id1164355841632',
      'title' => 'Using Models and the Scientific Processes'
    )
  end
end

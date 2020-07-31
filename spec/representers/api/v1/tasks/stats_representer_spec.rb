require 'rails_helper'

RSpec.describe Api::V1::Tasks::StatsRepresenter, type: :representer do
  let(:stat) do
    {
      period_id: 1,
      name: '1st period',
      total_count: 32,
      complete_count: 28,
      partially_complete_count: 2
    }
  end

  subject(:represented) { described_class.new(Hashie::Mash.new(stat)).to_hash }

  it 'represents the stats' do
    expect(represented).to eq(
      {
        'period_id' => '1',
        'name' => '1st period',
        'total_count' => 32,
        'complete_count' => 28,
        'partially_complete_count' => 2
      }
    )
  end
end

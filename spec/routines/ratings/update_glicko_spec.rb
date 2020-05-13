require 'rails_helper'

RSpec.describe Ratings::UpdateGlicko, type: :routine do
  let(:record)                    do
    FactoryBot.create :ratings_role_book_part,
                      glicko_mu: 0.0,
                      glicko_phi: 1.1513,
                      glicko_sigma: 0.06
  end
  let(:exercise_group_book_parts) do
    [
      Hashie::Mash.new(glicko_mu: -0.5756, glicko_phi: 0.1727, response: true ),
      Hashie::Mash.new(glicko_mu:  0.2878, glicko_phi: 0.5756, response: false),
      Hashie::Mash.new(glicko_mu:  1.1513, glicko_phi: 1.7269, response: false)
    ]
  end
  subject                         do
    described_class.call record: record, exercise_group_book_parts: exercise_group_book_parts
  end
  let(:outputs)                   { subject.outputs }

  let(:expected_sigma)            {  0.05999 }
  let(:expected_phi)              {  0.8722  }
  let(:expected_mu)               { -0.2069  }

  it 'returns expected values' do
    expect(outputs.sigma).to be_within(0.00001).of(expected_sigma)
    expect(outputs.phi).to be_within(0.0001).of(expected_phi)
    expect(outputs.mu).to be_within(0.0001).of(expected_mu)
  end
end

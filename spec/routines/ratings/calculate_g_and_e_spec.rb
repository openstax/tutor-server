require 'rails_helper'

RSpec.describe Ratings::CalculateGAndE, type: :routine do
  let(:record)                    do
    FactoryBot.create :ratings_role_book_part,
                      glicko_mu: 0.0,
                      glicko_phi: 1.1513,
                      glicko_sigma: 0.06
  end
  let(:exercise_group_book_parts) do
    [
      FactoryBot.create(:ratings_exercise_group_book_part, glicko_mu: -0.5756, glicko_phi: 0.1727),
      FactoryBot.create(:ratings_exercise_group_book_part, glicko_mu:  0.2878, glicko_phi: 0.5756),
      FactoryBot.create(:ratings_exercise_group_book_part, glicko_mu:  1.1513, glicko_phi: 1.7269)
    ]
  end
  subject                         do
    described_class.call record: record, exercise_group_book_parts: exercise_group_book_parts
  end
  let(:outputs)                   { subject.outputs            }

  let(:expected_g_array)          { [ 0.9955, 0.9531, 0.7242 ] }
  let(:expected_e_array)          { [ 0.639,  0.432,  0.303  ] }

  it 'returns expected values' do
    outputs.g_array.each_with_index do |g, index|
      expect(g).to be_within(0.0001).of(expected_g_array[index])
    end

    outputs.e_array.each_with_index do |e, index|
      expect(e).to be_within(0.001).of(expected_e_array[index])
    end
  end
end

require 'rails_helper'

RSpec.describe Ratings::UpdateGlicko, type: :routine do
  let(:record)                    do
    FactoryBot.create :ratings_role_book_part,
                      glicko_mu: 0.0,
                      glicko_phi: 1.1513,
                      glicko_sigma: 0.06
  end
  let(:exercise_mus)              { [ -0.5756, 0.2878, 1.1513 ] }
  let(:exercise_phis)             { [  0.1727, 0.5756, 1.7269 ] }
  let(:exercise_sigmas)           { [  0.06  , 0.06  , 0.06   ] }
  let(:exercise_group_book_parts) do
    [ true, false, false ].each_with_index.map do |response, index|
      Hashie::Mash.new(
        glicko_mu: exercise_mus[index],
        glicko_phi: exercise_phis[index],
        glicko_sigma: exercise_sigmas[index],
        response: response
      )
    end
  end
  subject                         do
    described_class.call(
      record: record,
      opponents: exercise_group_book_parts,
      update_opponents: update_opponents
    )
  end

  let(:expected_sigma)            {  0.05999 }
  let(:expected_phi)              {  0.8722  }
  let(:expected_mu)               { -0.2069  }

  context 'update_opponents is false' do
    let(:update_opponents) { false }

    it 'updates only the first record' do
      subject

      expect(record.glicko_sigma).to be_within(0.00001).of(expected_sigma)
      expect(record.glicko_phi).to be_within(0.0001).of(expected_phi)
      expect(record.glicko_mu).to be_within(0.0001).of(expected_mu)

      exercise_group_book_parts.each_with_index do |exercise_group_book_part, index|
        expect(exercise_group_book_part.glicko_sigma).to eq exercise_sigmas[index]
        expect(exercise_group_book_part.glicko_phi).to eq exercise_phis[index]
        expect(exercise_group_book_part.glicko_mu).to eq exercise_mus[index]
      end
    end
  end

  context 'update_opponents is true' do
    let(:update_opponents)  { true }

    let(:expected_exercise_mus)    { [ -0.5862, 0.4051, 1.6372 ] }
    let(:expected_exercise_phis)   { [  0.1823, 0.5624, 1.4481 ] }
    let(:expected_exercise_sigmas) { [  0.05999, 0.05999, 0.05999 ] }

    it 'updates the first record and the exercise records' do
      subject

      expect(record.glicko_sigma).to be_within(0.00001).of(expected_sigma)
      expect(record.glicko_phi).to be_within(0.0001).of(expected_phi)
      expect(record.glicko_mu).to be_within(0.0001).of(expected_mu)

      exercise_group_book_parts.each_with_index do |exercise_group_book_part, index|
        expect(exercise_group_book_part.glicko_sigma).to(
          be_within(0.00001).of(expected_exercise_sigmas[index])
        )
        expect(exercise_group_book_part.glicko_phi).to(
          be_within(0.0001).of(expected_exercise_phis[index])
        )
        expect(exercise_group_book_part.glicko_mu).to(
          be_within(0.0001).of(expected_exercise_mus[index])
        )
      end
    end
  end
end

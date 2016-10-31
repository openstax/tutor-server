require 'rails_helper'

RSpec.describe Api::V1::TermYearRepresenter, type: :representer do
  let(:term)           { [:legacy, :demo, :fall, :summer, :spring].sample }
  let(:year)           { Time.current.year }

  let(:term_year)      { TermYear.new(term, year) }

  let(:representation) { described_class.new(term_year).as_json }

  context 'term' do
    it 'can be read' do
      expect(representation['term']).to eq term.to_s
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(term_year).not_to receive(:term=)
      described_class.new(term_year).from_hash(term: 'test')
      expect(term_year.term).to eq term
    end
  end

  context 'year' do
    it 'can be read' do
      expect(representation['year']).to eq year
    end

    it 'can be written' do
      expect(term_year).not_to receive(:year=)
      described_class.new(term_year).from_hash(year: 1988)
      expect(term_year.year).to eq year
    end
  end
end

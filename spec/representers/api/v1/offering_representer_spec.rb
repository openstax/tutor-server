require 'rails_helper'

RSpec.describe Api::V1::OfferingRepresenter, type: :representer do
  let(:offering)       { FactoryGirl.create :catalog_offering }

  let(:representation) { described_class.new(offering).as_json }

  context 'id' do
    it 'can be read' do
      expect(representation['id']).to eq offering.id.to_s
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:id=)
      expect{ described_class.new(offering).from_hash(id: '42') }.not_to change{ offering.id }
    end
  end

  context 'is_concept_coach' do
    it 'can be read' do
      expect(representation['is_concept_coach']).to eq offering.is_concept_coach
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:is_concept_coach=)
      expect{ described_class.new(offering).from_hash(is_concept_coach: false) }.not_to(
        change{ offering.is_concept_coach }
      )
    end
  end

  context 'is_tutor' do
    it 'can be read' do
      expect(representation['is_tutor']).to eq offering.is_tutor
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:is_tutor=)
      expect{ described_class.new(offering).from_hash(is_tutor: false) }.not_to(
        change{ offering.is_tutor }
      )
    end
  end

  context 'appearance_code' do
    it 'can be read' do
      expect(representation['appearance_code']).to eq offering.appearance_code
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:appearance_code=)
      expect{ described_class.new(offering).from_hash(appearance_code: 'sociology') }.not_to(
        change{ offering.appearance_code }
      )
    end
  end

  context 'active_term_years' do
    it 'can be read' do
      expect(representation['active_term_years']).to eq(
        TermYear.visible_term_years.map do |term_year|
          Api::V1::TermYearRepresenter.new(term_year).as_json
        end
      )
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect{ described_class.new(offering).from_hash(active_term_years: []) }.not_to(
        change{ TermYear.visible_term_years }
      )
    end
  end
end

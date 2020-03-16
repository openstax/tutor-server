require 'rails_helper'

RSpec.describe Api::V1::OfferingRepresenter, type: :representer do
  let(:offering)       { FactoryBot.create :catalog_offering }

  let(:representation) { described_class.new(offering).as_json }

  context 'id' do
    it 'can be read' do
      expect(representation['id']).to eq offering.id.to_s
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:id=)
      expect { described_class.new(offering).from_hash('id' => '42') }.not_to change{ offering.id }
    end
  end

  context 'title' do
    it 'can be read' do
      expect(representation['title']).to eq offering.title
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:title=)
      expect { described_class.new(offering).from_hash('title' => 'Something') }.not_to(
        change { offering.title }
      )
    end
  end

  context 'description' do
    it 'can be read' do
      expect(representation['description']).to eq offering.description
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:description=)
      expect { described_class.new(offering).from_hash('description' => 'Something') }.not_to(
        change { offering.description }
      )
    end
  end

  context 'is_concept_coach' do
    it 'can be read' do
      expect(representation['is_concept_coach']).to eq offering.is_concept_coach
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:is_concept_coach=)
      expect { described_class.new(offering).from_hash('is_concept_coach' => false) }.not_to(
        change { offering.is_concept_coach }
      )
    end
  end

  context 'is_tutor' do
    it 'can be read' do
      expect(representation['is_tutor']).to eq offering.is_tutor
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:is_tutor=)
      expect { described_class.new(offering).from_hash('is_tutor' => false) }.not_to(
        change { offering.is_tutor }
      )
    end
  end

  context 'appearance_code' do
    it 'can be read' do
      expect(representation['appearance_code']).to eq offering.appearance_code
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:appearance_code=)
      expect { described_class.new(offering).from_hash('appearance_code' => 'sociology') }.not_to(
        change { offering.appearance_code }
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
      expect { described_class.new(offering).from_hash('active_term_years' => []) }.not_to(
        change { TermYear.visible_term_years }
      )
    end
  end

  context 'default_course_name' do
    it 'can be read' do
      expect(representation['default_course_name']).to eq offering.default_course_name
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:default_course_name=)
      expect { described_class.new(offering).from_hash('default_course_name' => 'Test') }.not_to(
        change { offering.default_course_name }
      )
    end
  end

  context 'does_cost' do
    it 'can be read' do
      expect(representation['does_cost']).to eq offering.does_cost
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:does_cost=)
      expect { described_class.new(offering).from_hash('does_cost' => 'true') }.not_to(
        change { offering.does_cost }
      )
    end
  end

  context 'is_preview_available' do
    it 'can be read' do
      expect(representation['is_preview_available']).to eq offering.is_preview_available
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:is_preview_available=)
      expect { described_class.new(offering).from_hash('is_preview_available' => 'true') }.not_to(
        change { offering.is_preview_available }
      )
    end
  end

  context 'is_available' do
    it 'can be read' do
      expect(representation['is_available']).to eq offering.is_available
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:is_available=)
      expect { described_class.new(offering).from_hash('is_available' => 'true') }.not_to(
        change { offering.is_available }
      )
    end
  end

  context 'preview_message' do
    it 'can be read' do
      expect(representation['preview_message']).to eq offering.preview_message
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect(offering).not_to receive(:preview_message=)
      expect { described_class.new(offering).from_hash('preview_message' => 'Hi') }.not_to(
        change { offering.preview_message }
      )
    end
  end
end

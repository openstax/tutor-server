require 'rails_helper'

RSpec.describe GenerateToken do
  let(:course) { Entity::Course.create! }
  let(:profile) { CourseProfile::Models::Profile.new(name: 'Cool name',
                                                     entity_course_id: course.id,
                                                     is_concept_coach: false) }

  describe '.apply!' do
    it 'saves a random hex to a record' do
      allow(SecureRandom).to receive(:hex) { '123987' }

      described_class.apply!(record: profile, attribute: :registration_token)

      expect(profile.reload.registration_token).to eq('123987')
    end

    it 'allows the caller to change the mode' do
      allow(SecureRandom).to receive(:urlsafe_base64) { 'abc_12-3' }

      described_class.apply!(record: profile,
                             attribute: :registration_token,
                             mode: :urlsafe_base64)

      expect(profile.reload.registration_token).to eq('abc_12-3')
    end
  end

  describe '.apply' do
    it 'does not save the record' do
      allow(SecureRandom).to receive(:hex) { '321789' }

      described_class.apply(record: profile, attribute: :registration_token)

      expect(profile.registration_token).to eq('321789')
      expect(profile.id).to be_blank
    end
  end
end

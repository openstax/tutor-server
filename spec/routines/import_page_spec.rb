require 'rails_helper'

RSpec.describe ImportPage, :type => :routine do
  CNX_ID = 'd6555a80-80d8-4829-9346-07ea9391f391@5'

  context 'without :no_reading option' do
    it 'creates a new Resource' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID)
      }.to change{ Resource.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs[:resource]).to be_persisted
    end

    it 'creates a new Reading' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID)
      }.to change{ Reading.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs[:reading]).to be_persisted
    end
  end

  context 'with :no_reading option' do
    it 'creates a new Resource' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID, no_reading: true)
      }.to change{ Resource.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs[:resource]).to be_persisted
    end

    it 'does not create a new Reading' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID, no_reading: true)
      }.not_to change{ Reading.count }
      expect(result.errors).to be_empty
      expect(result.outputs[:reading]).to be_nil
    end
  end

  xit 'converts absolute links to relative links' do
  end

  xit 'caches images from CNX' do
  end
end

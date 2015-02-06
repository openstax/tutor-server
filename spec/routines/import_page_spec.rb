require 'rails_helper'

RSpec.describe ImportPage, :type => :routine do
  CNX_ID = 'd6555a80-80d8-4829-9346-07ea9391f391@5'

  let!(:chapter) { FactoryGirl.create :chapter }

  context 'with the :chapter option' do
    it 'creates a new Resource' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID, chapter: chapter)
      }.to change{ Resource.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs[:resource]).to be_persisted
    end

    it 'creates a new Page' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID, chapter: chapter)
      }.to change{ Page.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs[:page]).to be_persisted
    end
  end

  context 'without the :chapter option' do
    it 'creates a new Resource' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID)
      }.to change{ Resource.count }.by(1)
      expect(result.errors).to be_empty
      expect(result.outputs[:resource]).to be_persisted
    end

    it 'does not create a new Page' do
      result = nil
      expect {
        result = ImportPage.call(CNX_ID)
      }.not_to change{ Page.count }
      expect(result.errors).to be_empty
      expect(result.outputs[:page]).to be_nil
    end
  end

  xit 'converts absolute links to relative links' do
  end

  xit 'caches images from CNX' do
  end
end

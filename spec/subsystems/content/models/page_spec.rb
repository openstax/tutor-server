require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Content::Models::Page, type: :model, vcr: VCR_OPTS do

  subject!(:page) { FactoryGirl.create :content_page }

  it { is_expected.to belong_to(:chapter) }
  it { is_expected.to validate_presence_of(:title) }

  it { is_expected.to delegate_method(:is_intro?).to(:parser) }

  context 'with snap lab page' do

    before(:all) do
      snap_lab_page_content = VCR.use_cassette('Content_Models_Page/with_snap_lab_page',
                                               VCR_OPTS) do
        OpenStax::Cnx::V1::Page.new(id: '9545b9a2-c371-4a31-abb9-3a4a1fff497b@8').content
      end

      @snap_lab_page = FactoryGirl.create :content_page, content: snap_lab_page_content,
                                                         fragments: nil, snap_labs: nil
    end

    it 'caches fragments' do
      expect(@snap_lab_page).not_to receive(:parser)
      expect(@snap_lab_page).not_to receive(:fragment_splitter)

      fragments = @snap_lab_page.fragments
      expect(fragments.map(&:class)).to eq([OpenStax::Cnx::V1::Fragment::Reading])
    end

    it 'caches snap labs' do
      expect(@snap_lab_page).not_to receive(:parser)
      expect(@snap_lab_page).not_to receive(:fragment_splitter)

      snap_labs = @snap_lab_page.snap_labs
      fragments = snap_labs.first[:fragments]
      expect(snap_labs).to eq([
        { id: 'fs-id1164355841632',
          title: 'Using Models and the Scientific Processes',
          fragments: fragments }
      ])
      expect(fragments.map(&:class)).to eq([
        OpenStax::Cnx::V1::Fragment::Reading,
        OpenStax::Cnx::V1::Fragment::Exercise
      ])
    end

    it 'returns snap labs with the page id' do
      snap_labs = @snap_lab_page.snap_labs_with_page_id
      fragments = snap_labs.first[:fragments]
      expect(snap_labs).to eq([
        { id: 'fs-id1164355841632',
          page_id: @snap_lab_page.id,
          title: 'Using Models and the Scientific Processes',
          fragments: fragments }
      ])
    end

  end

end

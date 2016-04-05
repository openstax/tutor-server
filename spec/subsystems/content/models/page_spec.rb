require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Content::Models::Page, type: :model, vcr: VCR_OPTS do

  subject { FactoryGirl.create :content_page }

  it { is_expected.to belong_to(:chapter) }
  it { is_expected.to validate_presence_of(:title) }

  context 'with snap lab page' do

    before(:all) do
      DatabaseCleaner.start

      snap_lab_page_content = VCR.use_cassette('Content_Models_Page/with_snap_lab_page',
                                               VCR_OPTS) do
        OpenStax::Cnx::V1::Page.new(id: '9545b9a2-c371-4a31-abb9-3a4a1fff497b@8').content
      end

      @snap_lab_page = FactoryGirl.create :content_page, content: snap_lab_page_content
    end

    after(:all) { DatabaseCleaner.clean }

    it 'returns snap labs' do
      snap_labs = @snap_lab_page.snap_labs
      fragments = snap_labs.first[:fragments]
      expect(snap_labs).to eq([
        { id: "#{@snap_lab_page.id}:fs-id1164355841632",
          title: 'Using Models and the Scientific Processes',
          fragments: fragments }
      ])
      expect(fragments.map(&:class)).to eq([
        OpenStax::Cnx::V1::Fragment::Reading,
        OpenStax::Cnx::V1::Fragment::Exercise
      ])
    end

  end

end

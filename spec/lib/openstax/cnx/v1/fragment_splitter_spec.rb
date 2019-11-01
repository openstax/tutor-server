require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::FragmentSplitter, type: :lib, vcr: VCR_OPTS do
  let(:reading_processing_instructions) do
    FactoryBot.build(:content_book).reading_processing_instructions
  end
  let(:reference_view_url) { Faker::Internet.url }

  let(:fragment_splitter)  do
    described_class.new reading_processing_instructions, reference_view_url
  end

  context 'with page' do
    before(:all) do
      @cnx_page_fragment_infos = [
        {
          id: '3005b86b-d993-4048-aff0-500256001f42',
          expected_hs_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Interactive,
                                         OpenStax::Cnx::V1::Fragment::Exercise,
                                         OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Exercise,
                                         OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Exercise,
                                         OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Exercise,
                                         OpenStax::Cnx::V1::Fragment::OptionalExercise],
          expected_worked_example_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading,
                                                     OpenStax::Cnx::V1::Fragment::OptionalExercise,
                                                     OpenStax::Cnx::V1::Fragment::Reading,
                                                     OpenStax::Cnx::V1::Fragment::OptionalExercise,
                                                     OpenStax::Cnx::V1::Fragment::Reading]
        },
        {
          id: '1bb611e9-0ded-48d6-a107-fbb9bd900851',
          expected_hs_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading]
        },
        {
          id: '95e61258-2faf-41d4-af92-f62e1414175a',
          expected_hs_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading]
        },
        {
          id: '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
          expected_hs_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading,
                                         OpenStax::Cnx::V1::Fragment::Video,
                                         OpenStax::Cnx::V1::Fragment::Exercise,
                                         OpenStax::Cnx::V1::Fragment::Interactive,
                                         OpenStax::Cnx::V1::Fragment::Exercise]
        }
      ]

      @cnx_page_fragment_infos.each do |hash|
        hash[:page] = OpenStax::Cnx::V1::Page.new(id: hash[:id])
      end

      VCR.use_cassette('OpenStax_Cnx_V1_FragmentSplitter/with_pages', VCR_OPTS) do
        @cnx_page_fragment_infos.each{ |hash| hash[:page].full_hash }
      end
    end

    it "splits the given pages into the expected fragments for HS" do
      hs_processing_instructions = FactoryBot.build(:content_book).reading_processing_instructions
      fragment_splitter = described_class.new hs_processing_instructions, reference_view_url

      @cnx_page_fragment_infos.each do |hash|
        fragments = fragment_splitter.split_into_fragments(hash[:page].converted_root)

        expect(fragments.map(&:class)).to eq hash[:expected_hs_fragment_classes]
      end
    end

    it "does not split reading steps before a worked example" do
      worked_example_processing_instructions = [
        { css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]',
          fragments: [], except: 'snap-lab' },
        { css: '.worked-example', fragments: ['node', 'optional_exercise'] }
      ]
      fragment_splitter = described_class.new(
        worked_example_processing_instructions, reference_view_url
      )

      hash = @cnx_page_fragment_infos.first
      fragments = fragment_splitter.split_into_fragments(hash[:page].converted_root)

      expect(fragments.map(&:class)).to eq hash[:expected_worked_example_fragment_classes]

      fragments.each_slice(2).each do |reading_fragment, optional_exercise_fragment|
        next if optional_exercise_fragment.nil? # Last fragment - not a worked example

        # The worked example node is included in the reading fragment before it
        node = Nokogiri::HTML.fragment(reading_fragment.to_html)
        expect(node.at_css('.worked-example')).to be_present
      end
    end
  end

end

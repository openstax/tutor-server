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
#      @ecosystem = generate_mini_ecosystem
      @cnx_page_fragment_infos = [
        {
          id: PopulateMiniEcosystem.cnx_page_hashes[0][:id],
          fragments: %w{Reading Video Exercise Reading},
          worked_examples: %w{Reading}
        },
        {
          id: PopulateMiniEcosystem.cnx_page_hashes[1][:id],
          fragments: %w{Reading Reading Reading Video Exercise Reading Reading Reading},
          worked_examples: %w{Reading}
        },
        {
          id: PopulateMiniEcosystem.cnx_page_hashes[2][:id],
          fragments: %w{Reading Video Exercise Reading Reading Interactive Exercise Reading},
          worked_examples: %w{Reading}
        },
        {
          id: PopulateMiniEcosystem.cnx_page_hashes[3][:id],
          fragments: %w{Reading Reading Reading Reading Reading Reading Interactive Exercise Reading},
          worked_examples: %w{Reading}
        },
        {
          id: PopulateMiniEcosystem.cnx_page_hashes[4][:id],
          fragments: %w{Reading},
          worked_examples: %w{Reading}
        },
      ]

      VCR.use_cassette('OpenStax_Cnx_V1_FragmentSplitter/with_pages', VCR_OPTS) do
        @cnx_page_fragment_infos.each do |hash|
          hash[:fragments].map!{ |fg| "OpenStax::Cnx::V1::Fragment::#{fg}".constantize }
          hash[:worked_examples].map!{ |fg| "OpenStax::Cnx::V1::Fragment::#{fg}".constantize }
          hash[:page] = OpenStax::Cnx::V1::Page.new(id: hash[:id]).tap do |page|
            page.convert_content!
          end
        end
      end
    end

    it 'splits the given pages into the expected fragments for HS' do
      hs_processing_instructions = FactoryBot.build(:content_book).reading_processing_instructions
      fragment_splitter = described_class.new hs_processing_instructions, reference_view_url
      @cnx_page_fragment_infos.each do |hash|
        fragments = fragment_splitter.split_into_fragments(hash[:page].root)
        expect(fragments.map(&:class)).to eq hash[:fragments]
      end
    end

    it 'does not split reading steps before a worked example' do
      worked_example_processing_instructions = [
        { css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]',
          fragments: [], except: 'snap-lab' },
        { css: '.worked-example', fragments: ['node', 'optional_exercise'] }
      ]
      fragment_splitter = described_class.new(
        worked_example_processing_instructions, reference_view_url
      )

      hash = @cnx_page_fragment_infos.first
      fragments = fragment_splitter.split_into_fragments(hash[:page].root)
      expect(fragments.map(&:class)).to eq hash[:worked_examples]

      fragments.each_slice(2).each do |reading_fragment, optional_exercise_fragment|
        next if optional_exercise_fragment.nil? # Last fragment - not a worked example

        # The worked example node is included in the reading fragment before it
        node = Nokogiri::HTML.fragment(reading_fragment.to_html)
        expect(node.at_css('.worked-example')).to be_present
      end
    end
  end
end

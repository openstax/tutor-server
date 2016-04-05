require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::FragmentSplitter, type: :lib, vcr: VCR_OPTS do
  let(:reading_processing_instructions) {
    [
      { css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]' },
      { css: '.ost-exercise-choice', fragments: ["exercise", "optional_exercise"] },
      { css: ".os-exercise", fragments: ["exercise"] },
      { css: ".ost-video", fragments: ["video"] },
      { css: ".os-interactive, .ost-interactive", fragments: ["interactive"] },
      { css: ".worked-example", fragments: ["reading"], labels: ["worked-example"] },
      { css: ".ost-feature, .ost-assessed-feature", fragments: ["reading"] }
    ]
  }

  let(:fragment_splitter)  { described_class.new(reading_processing_instructions) }

  let(:cnx_page_fragment_infos) {
    [
      {
        id: '3005b86b-d993-4048-aff0-500256001f42',
        expected_fragment_classes: [
          OpenStax::Cnx::V1::Fragment::Reading,
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
          OpenStax::Cnx::V1::Fragment::OptionalExercise
        ]
      },
      {
        id: '1bb611e9-0ded-48d6-a107-fbb9bd900851',
        expected_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading]
      },
      {
        id: '95e61258-2faf-41d4-af92-f62e1414175a',
        expected_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading]
      },
      {
        id: '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
        expected_fragment_classes: [OpenStax::Cnx::V1::Fragment::Reading,
                                    OpenStax::Cnx::V1::Fragment::Video,
                                    OpenStax::Cnx::V1::Fragment::Exercise,
                                    OpenStax::Cnx::V1::Fragment::Interactive,
                                    OpenStax::Cnx::V1::Fragment::Exercise]
      }
    ]
  }

  it "splits the given pages into the expected fragments" do
    cnx_page_fragment_infos.each do |hash|
      page = OpenStax::Cnx::V1::Page.new(id: hash[:id])
      fragments = fragment_splitter.split_into_fragments(page.converted_root)

      expect(fragments.map(&:class)).to eq hash[:expected_fragment_classes]
    end
  end

end

require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::TransformAndCachePageContent, type: :routine, vcr: VCR_OPTS do
  context 'with real content' do
    before(:all) do
      ox_page_1 = OpenStax::Content::Page.new(
        book: MINI_ECOSYSTEM_OPENSTAX_BOOK,
        uuid: '1b79a450-f691-4301-aef3-d065268ab4a9',
        title: 'Physical Quantities and Units'
      )
      ox_page_2 = OpenStax::Content::Page.new(
        book: MINI_ECOSYSTEM_OPENSTAX_BOOK,
        uuid: '20ecccca-ce8d-4067-9d78-b1cd34d9b582',
        title: "Introduction to Electric Current, Resistance, and Ohm's Law"
      )

      @book = FactoryBot.create :content_book,
                                archive_version: MINI_ECOSYSTEM_OPENSTAX_ARCHIVE_VERSION,
                                version: MINI_ECOSYSTEM_OPENSTAX_BOOK.version

      VCR.use_cassette("Content_Routines_TransformAndCachePageContent/with_book", VCR_OPTS) do
        [
          Content::Routines::ImportPage[
            ox_page: ox_page_1,
            book: @book,
            book_indices: [1, 2],
            parent_book_part_uuid: SecureRandom.uuid
          ],
          Content::Routines::ImportPage[
            ox_page: ox_page_2,
            book: @book,
            book_indices: [20, 0],
            parent_book_part_uuid: SecureRandom.uuid
          ]
        ]
      end
    end

    it 'calls resolve_links!, cache_fragments_and_snap_labs and save for all pages' do
      @book.pages.each do |page|
        expect(page).to receive(:resolve_links!)
        expect(page).to receive(:cache_fragments_and_snap_labs)
        expect(page).to receive(:save!)
      end

      described_class.call book: @book
    end
  end

  context 'with custom tags' do
    let(:exercise_tags_array) do
      [
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:2242a8c5-e8b1-4287-b801-af74ef6f1e5b'],
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:2242a8c5-e8b1-4287-b801-af74ef6f1e5b',
         'context-cnxfeature:fs-id1165298595412'],
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:2242a8c5-e8b1-4287-b801-af74ef6f1e5b',
         'context-cnxfeature:fs-id1169083561662', 'requires-context:y'],
        ['k12phys-ch03-s01-lo02', 'context-cnxmod:2242a8c5-e8b1-4287-b801-af74ef6f1e5b',
         'context-cnxfeature:fs-id1169083894428', 'requires-context:true'],
      ]
    end

    let(:wrappers) do
      exercise_tags_array.each_with_index.map do |exercise_tags, index|
        options = { number: index + 1, version: 1, tags: exercise_tags }
        content_hash = OpenStax::Exercises::V1::FakeClient.new_exercise_hash(options)

        OpenStax::Exercises::V1::Exercise.new(content: content_hash.to_json)
      end
    end

    before(:all) do
      DatabaseCleaner.start

      @book = FactoryBot.create :content_book,
                                archive_version: MINI_ECOSYSTEM_OPENSTAX_ARCHIVE_VERSION,
                                version: MINI_ECOSYSTEM_OPENSTAX_BOOK.version
      @ecosystem = @book.ecosystem

      ox_page = OpenStax::Content::Page.new(
        book: MINI_ECOSYSTEM_OPENSTAX_BOOK,
        uuid: '2242a8c5-e8b1-4287-b801-af74ef6f1e5b',
        title: 'Acceleration'
      )
      @page = VCR.use_cassette(
        'Content_Routines_TransformAndCachePageContent/with_custom_tags', VCR_OPTS
      ) do
        Content::Routines::ImportPage[
          ox_page: ox_page,
          book: @book,
          book_indices: [3, 1],
          parent_book_part_uuid: MINI_ECOSYSTEM_OPENSTAX_BOOK_HASH[:id],
        ]
      end
      @exercise_with_context = @book.exercises.reload.detect { |ex| ex.cnxfeatures.any? }
    end

    after(:all) { DatabaseCleaner.clean }

    before do
      expect(OpenStax::Exercises::V1).to receive(:exercises).once do |_, &block|
        block.call(wrappers)
      end

      Content::Routines::ImportExercises.call(
        ecosystem: @ecosystem,
        page: @page,
        query_hash: {}
      )

      Content::Routines::PopulateExercisePools.call book: @book
    end

    it 'assigns context for exercises that have cnxfeature tags' do
      imported_exercises = @ecosystem.exercises.order(:number).to_a
      imported_exercises.each { |ex| expect(ex.context).to be_nil }

      expect(@exercise_with_context.context).to be_nil
      expect { described_class.call book: @book }.not_to change { Content::Models::Exercise.count }
      @exercise_with_context.reload
      expect(@exercise_with_context.context).not_to be_nil
      context_node = Nokogiri::HTML.fragment(@exercise_with_context.context).children.first
      expect(@exercise_with_context.feature_ids).to include context_node.attr('id')
    end
  end
end

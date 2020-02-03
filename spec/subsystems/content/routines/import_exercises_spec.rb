require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportExercises, type: :routine, vcr: VCR_OPTS do

  context 'with a single tag' do
    let(:page)      { FactoryBot.create(:content_page) }
    let(:ecosystem) { page.book.ecosystem }

    before do
      original_call = described_class.method(:call)

      expect(described_class).to receive(:call) do |*args|
        VCR.use_cassette('Content_Routines_ImportExercises/with_a_single_tag', VCR_OPTS) do
          original_call.call(*args)
        end
      end.once
    end

    it 'imports all exercises' do
      expect do
        described_class.call(ecosystem: ecosystem, page: page,
                             query_hash: {tag: 'k12phys-ch04-s01-lo02'})
      end.to change{ Content::Models::Exercise.count }.by(16)

      exercises = ecosystem.exercises.order(:created_at).to_a
      exercises[-16..-1].each do |exercise|
        expect(exercise.exercise_tags.map{|et| et.tag.value}).to(
          include 'k12phys-ch04-s01-lo02'
        )
      end
    end
  end

  context 'with multiple tags' do
    let(:page)      { FactoryBot.create(:content_page) }
    let(:ecosystem) { page.book.ecosystem }

    before do
      original_call = described_class.method(:call)

      expect(described_class).to receive(:call) do |*args|
        VCR.use_cassette('Content_Routines_ImportExercises/with_multiple_tags', VCR_OPTS) do
          original_call.call(*args)
        end
      end.once
    end

    it 'imports all exercises' do
      tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      expect do
        described_class.call(ecosystem: ecosystem, page: page, query_hash: {tag: tags})
      end.to change{ Content::Models::Exercise.count }.by(33)

      exercises = ecosystem.exercises.order(:created_at).to_a
      exercises[-33..-1].each do |exercise|
        expect(exercise.exercise_tags.map{|et| et.tag.value} & tags).not_to be_empty
      end
    end

    it 'assigns all available tags to the imported exercises' do
      result = nil
      tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      expect do
        result = described_class.call(ecosystem: ecosystem, page: page, query_hash: {tag: tags})
      end.to change{ Content::Models::Tag.count }.by(59)

      exercises = ecosystem.exercises.order(:created_at).to_a
      exercises[-33..-1].each do |exercise|
        wrapper = OpenStax::Exercises::V1::Exercise.new(content: exercise.content)

        exercise.exercise_tags.map{|et| et.tag.value}.each do |tag|
          expect(wrapper.tags).to include tag
        end

        exercise.exercise_tags.joins(:tag).where(tag: {
          tag_type: Content::Models::Tag.tag_types[:lo]
        }).map{|et| et.tag.value}.each do |lo|
          expect(wrapper.los).to include lo
        end
      end
    end
  end

  context 'with custom tags' do
    let(:exercise_tags_array) do
      [
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509'],
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509',
         'context-cnxfeature:fs-idp56122560'],
        ['k12phys-ch03-s01-lo01', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509',
         'context-cnxfeature:fs-idp56122560', 'requires-context:y'],
        ['k12phys-ch03-s01-lo02', 'context-cnxmod:0e58aa87-2e09-40a7-8bf3-269b2fa16509',
         'context-cnxfeature:fs-idp42721584', 'requires-context:true'],
      ]
    end

    let(:wrappers) do
      exercise_tags_array.each_with_index.map do |exercise_tags, index|
        options = { number: index + 1, version: 1, tags: exercise_tags }
        content_hash = OpenStax::Exercises::V1::FakeClient.new_exercise_hash(options)

        OpenStax::Exercises::V1::Exercise.new(content: content_hash.to_json)
      end
    end

    let(:expected_context_node_ids) do
      [nil, nil, 'fs-idp56122560', 'fs-idp42721584']
    end

    before(:all) do
      book = FactoryBot.create :content_book

      @ecosystem = book.ecosystem

      cnx_page = OpenStax::Cnx::V1::Page.new(
        id: '0e58aa87-2e09-40a7-8bf3-269b2fa16509', title: 'Acceleration'
      )

      @page = VCR.use_cassette('Content_Routines_ImportExercises/with_custom_tags', VCR_OPTS) do
        Content::Routines::ImportPage[cnx_page: cnx_page, book: book, book_location: [3, 1]]
      end

      Content::Routines::TransformAndCachePageContent.call book: book
    end

    before do
      expect(OpenStax::Exercises::V1).to receive(:exercises).once do |_, &block|
        block.call(wrappers)
      end
    end

    it 'assigns context for exercises that require context' do
      tags = ['k12phys-ch03-s01-lo01', 'k12phys-ch03-s01-lo02']
      expect do
        described_class.call ecosystem: @ecosystem, page: @page, query_hash: {tag: tags}
      end.to change { Content::Models::Exercise.count }.by(4)

      imported_exercises = @ecosystem.exercises.order(:number).to_a
      imported_exercises.each_with_index do |exercise, index|
        expected_context_node_id = expected_context_node_ids[index]

        if expected_context_node_id.nil?
          expect(exercise.context).to be_nil
        else
          context_node = Nokogiri::HTML.fragment(exercise.context).children.first
          expect(context_node.attr('id')).to eq expected_context_node_id
        end
      end
    end

    it 'skips import of exercises that don\'t map to the available pages' do
      page_block = ->(wrapper) { nil }
      tags = ['k12phys-ch03-s01-lo01', 'k12phys-ch03-s01-lo02']
      expect do
        described_class.call ecosystem: @ecosystem, page: page_block, query_hash: {tag: tags}
      end.not_to change{ Content::Models::Exercise.count }
    end
  end

  context 'incoming free response exercises' do
    before(:all) do
      book = FactoryBot.create :content_book
      @ecosystem = book.ecosystem

      cnx_page = OpenStax::Cnx::V1::Page.new(
        id: '0e58aa87-2e09-40a7-8bf3-269b2fa16509', title: 'Acceleration'
      )

      @page = VCR.use_cassette('Content_Routines_ImportExercises/with_custom_tags', VCR_OPTS) do
        Content::Routines::ImportPage[cnx_page: cnx_page, book: book, book_location: [3, 1]]
      end
    end

    it 'skips import of any exercise with no answers' do
      stub_exercise_query([{tags: ['some-id-tag'], remove_answers: true}])
      expect do
        described_class.call(ecosystem: @ecosystem, page: @page,
                             query_hash: {tags: ['some-id-tag']})
      end.to change{Content::Models::Exercise.count}.by(0)
    end
  end

  def stub_exercise_query(array_of_exercise_options={})
    wrappers = array_of_exercise_options.map.with_index do |exercise_options, index|
      hash_options = exercise_options.except(:remove_answers).merge(number: index + 1, version: 1)
      content_hash = OpenStax::Exercises::V1::FakeClient.new_exercise_hash(hash_options)
                                                        .tap do |hash|
        hash[:questions].last[:answers] = [] if exercise_options[:remove_answers]
      end

      OpenStax::Exercises::V1::Exercise.new(content: content_hash.to_json)
    end

    expect(OpenStax::Exercises::V1).to receive(:exercises).and_return(wrappers).once
  end

end

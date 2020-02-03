require 'vcr_helper'

module PopulateExerciseContent
  def generate_homework_test_exercise_content
    cnx_page_hashes = [
      { id: '1bb611e9-0ded-48d6-a107-fbb9bd900851', title: 'Introduction' },
      { id: '95e61258-2faf-41d4-af92-f62e1414175a', title: 'Force' }
    ]

    cnx_chapter_hashes = [
      { title: "Dynamics: Force and Newton's Laws of Motion", contents: cnx_page_hashes }
    ]

    cnx_book_hash = {
      id: '93e2b09d-261c-4007-a987-0b3062fe154b',
      version: '4.4',
      title: 'College Physics with Courseware',
      tree: {
        id: '93e2b09d-261c-4007-a987-0b3062fe154b@4.4',
        title: 'College Physics with Courseware',
        contents: cnx_chapter_hashes
      }
    }

    cnx_book = OpenStax::Cnx::V1::Book.new hash: cnx_book_hash.deep_stringify_keys

    @book = FactoryBot.create :content_book, title: 'College Physics with Courseware'

    @ecosystem = FactoryBot.create :content_ecosystem

    reading_processing_instructions = FactoryBot.build(
      :content_book
    ).reading_processing_instructions

    @book = VCR.use_cassette(
      'Tasks_Assistants_HomeworkAssistant/for_Introduction_and_Force/with_pages', VCR_OPTS
    ) do
      Content::ImportBook.call(
        cnx_book: cnx_book,
        ecosystem: @ecosystem,
        reading_processing_instructions: reading_processing_instructions
      ).outputs.book
    end

    @pages = @book.pages

    @intro_step_gold_data = {
      klass: Tasks::Models::TaskedReading,
      title: "Forces and Newton's Laws of Motion",
      related_content: [
        { title: "Forces and Newton's Laws of Motion", book_location: [8, 1] }
      ]
    }

    @core_step_gold_data = [
      @intro_step_gold_data, {
        klass: Tasks::Models::TaskedReading,
        title: 'Force',
        related_content: [ { title: 'Force', book_location: [] } ]
      }
    ]

    @personalized_step_gold_data = []

    @spaced_practice_step_gold_data = [
      { group_type: 'spaced_practice_group', klass: Tasks::Models::TaskedPlaceholder }
    ] * 3

    @task_step_gold_data = \
      @core_step_gold_data + @personalized_step_gold_data + @spaced_practice_step_gold_data
  end
end

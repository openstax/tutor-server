require 'vcr_helper'

module PopulateExerciseContent
  def generate_homework_test_exercise_content
    cnx_page_hashes = [
      { 'id' => '1bb611e9-0ded-48d6-a107-fbb9bd900851', 'title' => 'Introduction' },
      { 'id' => '95e61258-2faf-41d4-af92-f62e1414175a', 'title' => 'Force' }
    ]

    @intro_step_gold_data = {
      klass: Tasks::Models::TaskedReading,
      title: "Forces and Newton's Laws of Motion",
      related_content: [
        {
          title: "Forces and Newton's Laws of Motion",
          book_location: [8, 1],
          baked_book_location: []
        }
      ]
    }

    @core_step_gold_data = [
      @intro_step_gold_data,
      { klass: Tasks::Models::TaskedReading,
        title: "Force",
        related_content: [{title: "Force", book_location: [8, 2], baked_book_location: []}] }
    ]

    @personalized_step_gold_data = []

    @spaced_practice_step_gold_data = [
      { group_type: 'spaced_practice_group', klass: Tasks::Models::TaskedPlaceholder }
    ] * 3

    @task_step_gold_data = \
      @core_step_gold_data + @personalized_step_gold_data + @spaced_practice_step_gold_data

    cnx_pages = cnx_page_hashes.map { |hash| OpenStax::Cnx::V1::Page.new(hash: hash) }

    @chapter = FactoryBot.create :content_chapter, title: "Forces and Newton's Laws of Motion"

    @ecosystem = ::Content::Ecosystem.new(strategy: ::Content::Strategies::Direct::Ecosystem.new(@chapter.book.ecosystem))

    @content_pages = VCR.use_cassette(
      'Tasks_Assistants_HomeworkAssistant/for_Introduction_and_Force/with_pages',
      VCR_OPTS
    ) do
      cnx_pages.map.with_index do |cnx_page, ii|
        Content::Routines::ImportPage.call(
          cnx_page:  cnx_page,
          chapter: @chapter,
          book_location: [8, ii+1]
        ).outputs.page.reload
      end
    end

    @pages = @content_pages.map{ |content_page| Content::Page.new(strategy: content_page.wrap) }

    Content::Routines::PopulateExercisePools[book: @chapter.book]
  end
end

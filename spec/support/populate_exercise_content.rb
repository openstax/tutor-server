module PopulateExerciseContent
  def self.included klass
    klass.class_eval do
      include PopulateMiniEcosystem
    end
  end

  def generate_homework_test_exercise_content
    @ecosystem = generate_mini_ecosystem

    @pages = @ecosystem.books.first.pages

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

class AddNumberOfQuestionsToContentExercises < ActiveRecord::Migration[5.2]
  def change
    add_column :content_exercises, :number_of_questions, :integer

    reversible do |dir|
      dir.up do
        Content::Models::Exercise.update_all(
          '"number_of_questions" = JSONB_ARRAY_LENGTH("question_answer_ids")'
        )
      end
    end

    change_column_null :content_exercises, :number_of_questions, false
  end
end

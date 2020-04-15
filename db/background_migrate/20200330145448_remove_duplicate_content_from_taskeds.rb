class RemoveDuplicateContentFromTaskeds < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    # Clear the content column for all TaskedReadings that have verbatim copies of the book content
    page_ids = Tasks::Models::TaskedReading.joins(:task_step)
                                           .where.not(content: nil)
                                           .distinct
                                           .pluck(Arel.sql('"tasks_task_steps"."content_page_id"'))
    Content::Models::Page.where(id: page_ids).find_each do |page|
      Tasks::Models::TaskedReading.transaction do
        page.fragments.each_with_index do |fragment, index|
          next unless fragment.respond_to? :to_html

          Tasks::Models::TaskedReading.joins(:task_step).where(
            task_step: { content_page_id: page.id, fragment_index: index },
            content: fragment.to_html
          ).update_all content: nil
        end
      end
    end

    Content::Models::Exercise.where(question_answer_ids: nil).find_each do |exercise|
      Tasks::Models::TaskedExercise.transaction do
        exercise.update_attribute :question_answer_ids, exercise.parser.question_answer_ids

        Tasks::Models::TaskedExercise.select(:id, :question_index)
                                     .where(content_exercise_id: exercise.id)
                                     .group_by(&:question_index).each do |question_index, tes|
          Tasks::Models::TaskedExercise.where(id: tes.map(&:id)).update_all(
            answer_ids: exercise.question_answer_ids[question_index]
          )
        end
      end
    end

    change_column_null :content_exercises, :question_answer_ids, false
    change_column_null :tasks_tasked_exercises, :answer_ids, false
  end

  def down
    change_column_null :tasks_tasked_exercises, :answer_ids, true
    change_column_null :content_exercises, :question_answer_ids, true
  end
end

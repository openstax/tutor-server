class AddClonedFromIdToGradingTemplates < ActiveRecord::Migration[5.2]
  def change
    add_reference :tasks_grading_templates, :cloned_from, index: true, foreign_key: {
      to_table: :tasks_grading_templates, on_update: :cascade, on_delete: :nullify
    }
  end
end

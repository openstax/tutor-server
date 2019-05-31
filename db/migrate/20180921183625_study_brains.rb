class StudyBrains < ActiveRecord::Migration[4.2]
  def change
    create_table :research_study_brains do |t|
      t.references :research_study, null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.text :name, :type, :code, null: false
    end
  end
end

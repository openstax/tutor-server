class StudyBrains < ActiveRecord::Migration
  def change
    create_table :research_brains do |t|
      t.references :research_study, null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.text :name, :code, null: false
      t.integer :subject_area, limit: 2 # use smallint for enum
    end
  end
end

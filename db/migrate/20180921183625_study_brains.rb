class StudyBrains < ActiveRecord::Migration
  def change
    create_table :research_brains do |t|
      t.references :research_cohort, null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.text :name, :code, null: false
      t.integer :domain, limit: 2 # use smallint for enum
      t.text :hook
    end
  end
end

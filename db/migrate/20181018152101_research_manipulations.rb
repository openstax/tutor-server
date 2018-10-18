class ResearchManipulations < ActiveRecord::Migration
  def change
    create_table :research_manipulations do |t|
      t.references :research_study, null: false, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }

      # we must retain the record of any manipulation even if the cohort or brain is deleted
      t.references :research_cohort, null: true, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :nullify }
      t.references :research_study_brain, null: true, index: true,
                   foreign_key: { on_update: :cascade, on_delete: :nullify }

      t.references :target, polymorphic: true
      t.jsonb :context, null: false, default: '{}'
      t.timestamp :created_at
    end
  end
end

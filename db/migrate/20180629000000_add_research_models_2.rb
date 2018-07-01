class AddResearchModels2 < ActiveRecord::Migration
  def change
    create_table :research_cohorts do |t|
      t.references :research_study,             null: false, index: true,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :name,                           null: false
      t.integer :cohort_members_count,          null: false, default: 0
      t.boolean :is_accepting_members,          null: false, default: true

      t.timestamps                              null: false
    end

    create_table :research_cohort_members do |t|
      t.references :research_cohort,            null: false, index: true,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :course_membership_student,  null: false, index: true,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps                              null: false
    end

    add_column :research_studies, :activate_at, :datetime
    add_column :research_studies, :deactivate_at, :datetime

    add_column :research_studies, :last_activated_at, :datetime
    add_index :research_studies, :last_activated_at

    add_column :research_studies, :last_deactivated_at, :datetime
    add_index :research_studies, :last_deactivated_at

    add_column :research_surveys, :deleted_at, :datetime
    add_index :research_surveys, :deleted_at
  end
end

class CreateSalesforceCourseClassSize < ActiveRecord::Migration
  def change
    create_table :salesforce_course_class_sizes do |t|
      t.references :entity_course, null: false, index: true,
                                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :class_size_id
    end
  end
end

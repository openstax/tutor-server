class CreateSchools < ActiveRecord::Migration
  def change
    create_table :course_detail_schools do |t|
      t.string :name, null: false, unique: true
      t.references :course_detail_district, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

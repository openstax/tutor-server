class CreateSchoolDistrictSchools < ActiveRecord::Migration
  def change
    create_table :school_district_schools do |t|
      t.string :name, null: false, unique: true
      t.references :school_district_district, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

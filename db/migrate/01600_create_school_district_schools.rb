class CreateSchoolDistrictSchools < ActiveRecord::Migration[4.2]
  def change
    create_table :school_district_schools do |t|
      t.string :name, null: false, unique: true
      t.references :school_district_district, index: true, foreign_key: { on_update: :cascade,
                                                                          on_delete: :nullify }

      t.timestamps null: false
    end
  end
end

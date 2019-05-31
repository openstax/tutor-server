class CreateSchoolDistrictDistricts < ActiveRecord::Migration[4.2]
  def change
    create_table :school_district_districts do |t|
      t.string :name, null: false, unique: true
    end
  end
end

class CreateSchoolDistrictDistricts < ActiveRecord::Migration
  def change
    create_table :school_district_districts do |t|
      t.string :name, null: false, unique: true
    end
  end
end

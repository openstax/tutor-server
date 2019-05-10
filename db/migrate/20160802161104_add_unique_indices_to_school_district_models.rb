class AddUniqueIndicesToSchoolDistrictModels < ActiveRecord::Migration[4.2]
  def change
    add_index :school_district_districts, :name, unique: true
    add_index :school_district_schools, [:name, :school_district_district_id], unique: true,
              name: 'index_schools_on_name_and_district_id'
    add_index :school_district_schools, :name, unique: true,
              where: 'school_district_district_id IS NULL'
  end
end

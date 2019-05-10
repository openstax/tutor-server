class AddDefaultCourseNameToCatalogOffering < ActiveRecord::Migration[4.2]
  def change
    add_column :catalog_offerings, :default_course_name, :string
  end
end

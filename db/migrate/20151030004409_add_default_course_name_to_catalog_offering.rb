class AddDefaultCourseNameToCatalogOffering < ActiveRecord::Migration
  def change
    add_column :catalog_offerings, :default_course_name, :string
  end
end

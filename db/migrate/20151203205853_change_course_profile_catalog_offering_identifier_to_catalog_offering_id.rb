class ChangeCourseProfileCatalogOfferingIdentifierToCatalogOfferingId < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_profiles, :catalog_offering_id, :integer

    remove_column :course_profile_profiles, :catalog_offering_identifier

    add_index :course_profile_profiles, :catalog_offering_id
    add_foreign_key :course_profile_profiles, :catalog_offerings,
                    on_update: :cascade, on_delete: :cascade
  end
end

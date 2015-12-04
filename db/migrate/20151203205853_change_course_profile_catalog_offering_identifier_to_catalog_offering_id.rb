class ChangeCourseProfileCatalogOfferingIdentifierToCatalogOfferingId < ActiveRecord::Migration
  def change
    add_column :course_profile_profiles, :catalog_offering_id, :integer

    reversible do |dir|
      CourseProfile::Models::Profile.find_each do |profile|
        dir.up do
          offering_id = Catalog::Models::Offering
                          .where(identifier: profile.catalog_offering_identifier).pluck(:id).first
          profile.update_attribute(:catalog_offering_id, offering_id) unless offering_id.nil?
        end

        dir.down do
          offering_identifier = Catalog::Models::Offering
                                  .where(id: profile.catalog_offering_id).pluck(:identifier).first
          profile.update_attribute(:catalog_offering_identifier, offering_identifier) \
            unless offering_identifier.nil?
        end
      end
    end

    remove_column :course_profile_profiles, :catalog_offering_identifier

    add_index :course_profile_profiles, :catalog_offering_id
    add_foreign_key :course_profile_profiles, :catalog_offerings,
                    on_update: :cascade, on_delete: :cascade
  end
end

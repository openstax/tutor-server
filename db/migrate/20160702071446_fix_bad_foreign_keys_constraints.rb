class FixBadForeignKeysConstraints < ActiveRecord::Migration
  def up
    remove_foreign_key :catalog_offerings, :content_ecosystems
    remove_foreign_key :course_profile_profiles, :catalog_offerings

    add_foreign_key :catalog_offerings, :content_ecosystems,
                    on_update: :cascade, on_delete: :nullify
    add_foreign_key :course_profile_profiles, :catalog_offerings,
                    on_update: :cascade, on_delete: :nullify
  end

  def down
    remove_foreign_key :catalog_offerings, :content_ecosystems
    remove_foreign_key :course_profile_profiles, :catalog_offerings

    add_foreign_key :catalog_offerings, :content_ecosystems,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :course_profile_profiles, :catalog_offerings,
                    on_update: :cascade, on_delete: :cascade
  end
end

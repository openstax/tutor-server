class AddIsPreviewAvailableAndPreviewOnlyMessageToCatalogOfferings < ActiveRecord::Migration[5.2]
  def change
    add_column :catalog_offerings, :is_preview_available, :boolean
    add_column :catalog_offerings, :preview_message, :text

    reversible do |dir|
      dir.up do
        Catalog::Models::Offering.update_all(
          '"is_preview_available" = "is_available" AND "is_tutor"'
        )
      end
    end

    change_column_null :catalog_offerings, :is_preview_available, false
  end
end

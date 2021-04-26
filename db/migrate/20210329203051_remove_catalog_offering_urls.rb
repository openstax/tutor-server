class RemoveCatalogOfferingUrls < ActiveRecord::Migration[5.2]
  def change
    remove_column :catalog_offerings, :webview_url
    remove_column :catalog_offerings, :pdf_url
  end
end

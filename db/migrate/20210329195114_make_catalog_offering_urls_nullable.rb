class MakeCatalogOfferingUrlsNullable < ActiveRecord::Migration[5.2]
  def change
    change_column_null :catalog_offerings, :webview_url, true
    change_column_null :catalog_offerings, :pdf_url, true
  end
end

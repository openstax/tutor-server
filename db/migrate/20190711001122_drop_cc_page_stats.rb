class DropCcPageStats < ActiveRecord::Migration[5.2]
  def change
    execute 'DROP MATERIALIZED VIEW IF EXISTS cc_page_stats;'
  end
end

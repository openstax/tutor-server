module Tasks
  class CcPageStatsView < ActiveRecord::Base
    self.table_name = "cc_page_stats"

    def self.refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: true)
    end
  end
end

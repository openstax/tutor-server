desc 'Refreshes the materialized view that caches CC page stats'
task :refresh_cc_stats_view => :environment do
  Tasks::Models::ConceptCoachTask.connection
    .execute 'refresh materialized view concurrently cc_page_stats'
end

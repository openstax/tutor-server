class CacheExistingPeriods < ActiveRecord::Migration
  def up
    CourseMembership::Models::Period.find_in_batches(batch_size: 10) do |periods|
      Tasks::UpdatePeriodCaches.perform_later periods: periods
    end
  end

  def down
  end
end

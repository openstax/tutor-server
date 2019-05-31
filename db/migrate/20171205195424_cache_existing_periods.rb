class CacheExistingPeriods < ActiveRecord::Migration[4.2]
  def up
    CourseMembership::Models::Period.select(:id).find_in_batches(batch_size: 10) do |periods|
      Tasks::UpdatePeriodCaches.perform_later period_ids: periods.map(&:id)
    end
  end

  def down
  end
end

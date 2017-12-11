class FixExistingTaskCaches < ActiveRecord::Migration
  def up
    Tasks::Models::TaskCache.find_in_batches(batch_size: 100) do |task_caches|
      task_caches.each do |task_cache|
        toc = task_cache.as_toc

        task_cache.as_toc = toc.merge(
          num_known_location_steps: toc[:books].sum { |bk| bk[:num_assigned_steps] }
        )
      end

      Tasks::Models::TaskCache.import task_caches, validate: false, on_duplicate_key_update: {
        conflict_target: [ :tasks_task_id, :content_ecosystem_id ], columns: [ :as_toc ]
      }
    end
  end

  def down
  end
end

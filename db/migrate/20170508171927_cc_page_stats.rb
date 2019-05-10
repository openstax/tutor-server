class CcPageStats < ActiveRecord::Migration[4.2]

    def change
      create_view :cc_page_stats, materialized: true
      add_index :cc_page_stats, %w{course_period_id coach_task_content_page_id group_type},
                unique: true, name: 'cc_page_stats_uniq'
      add_index :cc_page_stats, :course_period_id
    end

end

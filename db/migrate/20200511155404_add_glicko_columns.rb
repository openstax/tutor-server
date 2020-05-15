class AddGlickoColumns < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_tasks, :role_book_part_job_id, :integer
    add_column :tasks_tasks, :period_book_part_job_id, :integer

    Delayed::Job.where("handler ILIKE '%UpdateRoleBookParts%'").delete_all
    Delayed::Job.where("handler ILIKE '%UpdatePeriodBookParts%'").delete_all

    Ratings::RoleBookPart.delete_all

    add_column :ratings_role_book_parts, :tasked_exercise_ids, :integer, array: true, null: false
    add_column :ratings_role_book_parts, :glicko_mu, :float, null: false
    add_column :ratings_role_book_parts, :glicko_phi, :float, null: false
    add_column :ratings_role_book_parts, :glicko_sigma, :float, null: false

    remove_column :ratings_role_book_parts, :num_responses

    Ratings::PeriodBookPart.delete_all

    add_column :ratings_period_book_parts, :tasked_exercise_ids, :integer, array: true, null: false
    add_column :ratings_period_book_parts, :glicko_mu, :float, null: false
    add_column :ratings_period_book_parts, :glicko_phi, :float, null: false
    add_column :ratings_period_book_parts, :glicko_sigma, :float, null: false

    remove_column :ratings_period_book_parts, :num_responses

    BackgroundMigrate.perform_later 'up', 20200515140524
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

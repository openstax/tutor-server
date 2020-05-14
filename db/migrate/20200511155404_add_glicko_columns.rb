class AddGlickoColumns < ActiveRecord::Migration[5.2]
  def up
    add_column :tasks_tasks, :role_book_part_job_id, :integer
    add_column :tasks_tasks, :period_book_part_job_id, :integer

    add_column :ratings_role_book_parts, :tasked_exercise_ids, :integer, array: true
    add_column :ratings_role_book_parts, :glicko_mu, :float
    add_column :ratings_role_book_parts, :glicko_phi, :float
    add_column :ratings_role_book_parts, :glicko_sigma, :float

    add_column :ratings_period_book_parts, :tasked_exercise_ids, :integer, array: true
    add_column :ratings_period_book_parts, :glicko_mu, :float
    add_column :ratings_period_book_parts, :glicko_phi, :float
    add_column :ratings_period_book_parts, :glicko_sigma, :float

    # TODO: Migrate data

    remove_column :ratings_role_book_parts, :num_responses
    remove_column :ratings_period_book_parts, :num_responses
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

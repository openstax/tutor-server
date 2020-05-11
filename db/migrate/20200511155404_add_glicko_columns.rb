class AddGlickoColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :ratings_role_book_parts, :glicko_mu, :float
    add_column :ratings_role_book_parts, :glicko_phi, :float
    add_column :ratings_role_book_parts, :glicko_sigma, :float

    add_column :ratings_period_book_parts, :glicko_mu, :float
    add_column :ratings_period_book_parts, :glicko_phi, :float
    add_column :ratings_period_book_parts, :glicko_sigma, :float
  end
end

class CreateShortCodeShortCodes < ActiveRecord::Migration[4.2]
  def change
    create_table :short_code_short_codes do |t|
      t.string :code, null: false
      t.text :uri, null: false
    end

    add_index :short_code_short_codes, :code, unique: true
  end
end

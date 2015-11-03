ActiveRecord::Schema.define(version: 1) do
  if table_exists?(:dummy_models)
    unless column_exists?(:dummy_models, :enrollment_code)
      add_column :dummy_models, :enrollment_code, :string
    end
  else
    create_table :dummy_models do |t|
      t.string :enrollment_code
    end
  end
end

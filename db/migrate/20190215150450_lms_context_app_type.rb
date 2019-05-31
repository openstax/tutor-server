class LmsContextAppType < ActiveRecord::Migration[4.2]
  def up
    add_column :lms_contexts, :app_type, :text
    execute "update lms_contexts set app_type = '#{Lms::Models::App.to_s}'"
    change_column_null :lms_contexts, :app_type, false
  end

  def down
    remove_column :lms_contexts, :app_type
  end
end

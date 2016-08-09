class AddProfileUiSettings < ActiveRecord::Migration
  def change

    add_column :user_profiles, :ui_settings, :text

  end
end

class AddProfileUiSettings < ActiveRecord::Migration[4.2]
  def change

    add_column :user_profiles, :ui_settings, :text

  end
end

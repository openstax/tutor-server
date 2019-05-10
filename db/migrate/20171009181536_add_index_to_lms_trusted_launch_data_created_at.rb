class AddIndexToLmsTrustedLaunchDataCreatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :lms_trusted_launch_data, :created_at
  end
end

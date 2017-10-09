class AddIndexToLmsTrustedLaunchDataCreatedAt < ActiveRecord::Migration
  def change
    add_index :lms_trusted_launch_data, :created_at
  end
end

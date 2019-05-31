class AddCreatedAtToLmsTrustedLaunchData < ActiveRecord::Migration[4.2]
  def change
    # add a default since some dev environment instances may already exist
    add_column :lms_trusted_launch_data, :created_at, :datetime, null: false, default: '2017-09-14 00:00:00'
  end
end

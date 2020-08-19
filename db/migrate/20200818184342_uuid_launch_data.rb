class UuidLaunchData < ActiveRecord::Migration[5.2]
  def change
    # TODO: next release replace id with uuid
    # if we do that now launches in use will break
    add_column :lms_trusted_launch_data, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_index :lms_trusted_launch_data, :uuid, unique: true
  end
end

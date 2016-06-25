class CacheContentPageFragmentsAndSnapLabs < ActiveRecord::Migration
  def up
    # This migration has been split in 2 so that it works with the model changes
    # End result should be the same regardless

    # The fragment and snap_lab caching has most likely already been done by this point,
    # but just in case...
    Content::Models::Page.find_each(batch_size: 100, &:save!)

    # The columns have already been set to null: false by the previous migration
  end

  def down
  end
end

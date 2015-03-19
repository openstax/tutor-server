class RemoveTaskedVideoVideoUrl < ActiveRecord::Migration
  def change
    remove_column :tasked_videos, :video_url
  end
end

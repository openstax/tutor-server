class AddPracticeStats < ActiveRecord::Migration[5.2]
  def up
    Stats::Generate.call
  end
end

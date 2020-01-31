class GenerateNewStats < ActiveRecord::Migration[5.2]
  def up
    # then generate the stats
    Stats::Generate.call
  end
end

class FixContentEcosystemTitles < ActiveRecord::Migration
  def up
    Content::Models::Ecosystem.find_each { |ecosystem| ecosystem.update_title }
  end

  def down
  end
end

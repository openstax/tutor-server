class FixContentEcosystemTitles < ActiveRecord::Migration
  def up
    Content::Models::Ecosystem.unscoped.find_each do |ecosystem|
      ecosystem.update_attribute :title, ecosystem.set_title
    end
  end

  def down
  end
end

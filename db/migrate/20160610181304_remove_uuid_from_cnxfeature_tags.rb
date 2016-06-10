class RemoveUuidFromCnxfeatureTags < ActiveRecord::Migration
  def up
    Content::Models::Tag.where{value.like 'context-cnxfeature:%#%'}.update_all("value = regexp_replace(value, '^context-cnxfeature:[\\w-]+#([\\w-]+)$', 'context-cnxfeature:\\1')")
  end

  def down
  end
end

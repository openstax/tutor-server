class PrependRToResearchIdentifiers < ActiveRecord::Migration
  def up
    Entity::Role.where('"research_identifier" NOT ILIKE \'r%\'')
                .update_all('"research_identifier" = \'r\' || "research_identifier"')
  end

  def down
  end
end

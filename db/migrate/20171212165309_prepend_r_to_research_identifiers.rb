class PrependRToResearchIdentifiers < ActiveRecord::Migration[4.2]
  def up
    Entity::Role.where(research_identifier: nil).find_each do |role|
      role.send :generate_unique_token, :research_identifier, mode: :hex, length: 4, prefix: 'r'
      role.save!
    end

    change_column_null :entity_roles, :research_identifier, false

    Entity::Role.where('"research_identifier" NOT ILIKE \'r%\'')
                .update_all('"research_identifier" = \'r\' || "research_identifier"')
  end

  def down
  end
end

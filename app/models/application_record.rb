class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Tutor::SubSystems::AssociationExtensions
  # if we don't calculate the table name ourselves
  # Rails will use the "Models" namespace as part of the name
  # ending up with tables names like "entity/models_books"
  #
  # The superclass logic is taken from
  # active_record/model_schema.rb's compute_table_name method
  def self.table_name
    base = base_class
    if self == base
      parts=self.to_s.split("::")
      parts.first.underscore + "_" + parts.last.tableize
    else
      # STI subclass should use superclass' table
      base.table_name
    end
  end
end

# https://github.com/rails/rails/issues/32374#issuecomment-378122738
module ActiveRecord
  class TableMetadata

    def associated_table(table_name)
      association = klass._reflect_on_association(table_name) || klass._reflect_on_association(table_name.to_s.singularize)

      if !association && table_name == arel_table.name
        return self
      elsif association && !association.polymorphic?
        association_klass = association.klass
        arel_table = association_klass.arel_table
      else
        type_caster = TypeCaster::Connection.new(klass, table_name)
        association_klass = nil
        arel_table = Arel::Table.new(table_name, type_caster: type_caster)
      end

      TableMetadata.new(association_klass, arel_table, association)
    end

  end
end

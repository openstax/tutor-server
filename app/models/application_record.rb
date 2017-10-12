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

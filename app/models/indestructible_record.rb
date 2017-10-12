class IndestructibleRecord < ApplicationRecord
  self.abstract_class = true

  before_destroy do
    raise ActiveRecord::IndestructibleRecord, "#{self.class.name} is marked as indestructible"
  end

  def delete
    destroy
  end
end

class Entity::Role < ActiveRecord::Base
  enum role_type: [:unassigned, :teacher, :student]
end

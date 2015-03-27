class Entity::Models::Role < Tutor::SubSystems::BaseModel
  enum role_type: [:unassigned, :teacher, :student]
end

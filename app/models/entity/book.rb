class Entity::Book < Tutor::SubSystems::BaseModel
  has_one :root_book_part, -> { where parent_book_part: nil }, class_name: '::Content::Models::BookPart'
end


class Cache::RoleBookPart < ApplicationRecord
  belongs_to :role, subsystem: :entity, inverse_of: :role_book_parts

  validates :book_part_uuid, presence: true, uniqueness: { scope: :entity_role_id }
  validates :clue, presence: true
end

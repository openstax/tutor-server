module Content
  module Models
    class Note < ApplicationRecord
      belongs_to :page, subsystem: :content
      belongs_to :role, subsystem: :entity

      has_one :chapter, through: :page
      has_one :book, through: :chapter
      has_one :ecosystem, through: :book

      validates :page, :role, presence: true
    end
  end
end

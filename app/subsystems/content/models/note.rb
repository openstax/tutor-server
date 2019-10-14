module Content
  module Models
    class Note < ApplicationRecord
      attr_accessor :course_id

      belongs_to :page, subsystem: :content
      belongs_to :role, subsystem: :entity

      has_one :chapter, through: :page
      has_one :book, through: :chapter
      has_one :ecosystem, through: :book
    end
  end
end

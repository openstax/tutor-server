module Content
  module Models
    class Ecosystem < Tutor::SubSystems::BaseModel

      wrapped_by ::Content::Strategies::Direct::Ecosystem

      has_many :course_ecosystems, dependent: :destroy, subsystem: :course_content
      has_many :courses, through: :course_ecosystems, subsystem: :entity

      has_many :books, dependent: :destroy, inverse_of: :ecosystem
      has_many :chapters, through: :books
      has_many :pages, through: :chapters
      has_many :exercises, through: :pages
      has_many :pools, through: :pages

      has_many :tags, dependent: :destroy, inverse_of: :ecosystem

      validates :title, presence: true, uniqueness: true

    end
  end
end

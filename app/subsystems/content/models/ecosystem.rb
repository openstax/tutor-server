module Content
  module Models
    class Ecosystem < Tutor::SubSystems::BaseModel

      wrapped_by ::Ecosystem::Strategies::Direct::Ecosystem

      has_many :books, dependent: :destroy, inverse_of: :ecosystem
      has_many :chapters, through: :books
      has_many :pages, through: :chapters
      has_many :exercises, through: :pages
      has_many :pools, through: :pages

    end
  end
end

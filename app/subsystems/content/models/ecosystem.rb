module Content
  module Models
    class Ecosystem < Tutor::SubSystems::BaseModel

      wrapped_by ::Ecosystem::Strategies::Direct::Ecosystem

      has_many :books, dependent: :destroy
      has_many :chapters, through: :books
      has_many :pages, through: :chapters
      has_many :exercises, through: :pages

    end
  end
end

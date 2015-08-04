module Content
  module Models
    class Ecosystem < Tutor::SubSystems::BaseModel

      wrapped_by ::Ecosystem::Strategies::Direct::Ecosystem

      has_many :books, dependent: :destroy

    end
  end
end

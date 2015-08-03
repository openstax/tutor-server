module Ecosystem
  module Models
    class Ecosystem < Tutor::SubSystems::BaseModel

      wrapped_by ::Ecosystem::Strategies::Direct

      has_many :books, subsystem: :content, dependent: :destroy

    end
  end
end

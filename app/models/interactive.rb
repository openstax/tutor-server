class Interactive < ActiveRecord::Base
  belongs_to_resource

  has_many :book_interactives, dependent: :destroy
end

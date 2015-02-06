class Book < ActiveRecord::Base
  belongs_to_resource

  has_many :chapters, dependent: :destroy
end

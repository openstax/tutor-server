class Interactive < ActiveRecord::Base
  belongs_to_resource

  has_many :page_interactives, dependent: :destroy
end

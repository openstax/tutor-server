class Page < ActiveRecord::Base
  belongs_to_resource

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages

  has_many :page_exercises, dependent: :destroy
  has_many :page_interactives, dependent: :destroy

  validates :chapter, presence: true
end

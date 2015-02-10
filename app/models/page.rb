class Page < ActiveRecord::Base
  belongs_to_resource

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages

  has_many :page_topics, dependent: :destroy

  validates :chapter, presence: true
end

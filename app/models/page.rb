class Page < ActiveRecord::Base
  belongs_to_resource

  sortable_belongs_to :book, on: :number, inverse_of: :pages

  has_many :page_topics, dependent: :destroy

  validates :resource, presence: true
  validates :title, presence: true
  validates :cnx_id, presence: true
  validates :version, presence: true, uniqueness: { scope: :cnx_id }
end

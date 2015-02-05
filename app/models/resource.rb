class Resource < ActiveRecord::Base

  has_one :book, dependent: :destroy
  has_one :reading, dependent: :destroy
  has_one :exercise, dependent: :destroy
  has_one :interactive, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validates :title, presence: true
  validates :version, presence: true, uniqueness: { scope: :title }

  def content
    cached_content # TODO: caching
  end
end

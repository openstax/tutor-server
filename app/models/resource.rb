class Resource < ActiveRecord::Base

  has_one :page, dependent: :destroy
  has_one :exercise, dependent: :destroy
  has_one :interactive, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  def content
    cached_content # TODO: caching
  end

end

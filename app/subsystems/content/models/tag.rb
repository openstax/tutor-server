class Content::Tag < ActiveRecord::Base
  has_many :page_tags, dependent: :destroy
  has_many :exercise_tags, dependent: :destroy

  # List the different types of tags
  enum tag_type: [ :generic, :lo ]

  validates :name, presence: true
  validates :tag_type, presence: true
end

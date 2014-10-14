class Interactive < ActiveRecord::Base
  belongs_to :resource, dependent: :destroy
  has_one_task

  validates :resource, presence: true

  delegate :url, :content, to: :resource
end

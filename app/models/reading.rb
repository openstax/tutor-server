class Reading < ActiveRecord::Base
  has_one_task_step

  belongs_to :resource, dependent: :destroy

  validates :resource, presence: true

  delegate :url, :content, to: :resource
end

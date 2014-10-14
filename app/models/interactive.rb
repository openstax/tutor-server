class Interactive < ActiveRecord::Base
  belongs_to :resource, dependent: :destroy
  has_one_task

  delegate :url, :content, to: :resource
end

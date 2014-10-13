

class Reading < ActiveRecord::Base
  belongs_to :resource
  has_one_task

  delegate :url, :content, to: :resource
end

class TaskedReading < ActiveRecord::Base
  acts_as_tasked

  validates :url, presence: true
  validates :content, presence: true
end

class Tasks::Models::TaskedReading < IndestructibleRecord
  acts_as_tasked

  json_serialize :book_location, Integer, array: true

  validates :url, presence: true
  validates :content, presence: true

  def has_content?
    true
  end
end

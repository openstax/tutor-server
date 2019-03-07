class Tasks::Models::TaskedExternalUrl < IndestructibleRecord
  acts_as_tasked

  validates :url, presence: true

  def content_preview
    "#{title}: #{description}"
  end
end

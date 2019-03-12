class Tasks::Models::TaskedVideo < IndestructibleRecord
  acts_as_tasked

  validates :url, presence: true
  validates :content, presence: true

  def has_content?
    true
  end

  def content_preview
    title || "External Reading step ##{id}"
  end
end

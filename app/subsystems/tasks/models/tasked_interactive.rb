class Tasks::Models::TaskedInteractive < IndestructibleRecord
  acts_as_tasked

  validates :url, presence: true
  validates :content, presence: true

  def has_content?
    true
  end

  def content_preview
    title || "External Interactive step ##{id}"
  end
end

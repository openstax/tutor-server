class Tasks::Models::TaskedExternalUrl < IndestructibleRecord
  acts_as_tasked

  validates :url, presence: true
end

class Tasks::Models::TaskedPlaceholder < ApplicationRecord
  acts_as_tasked

  enum placeholder_type: [:unknown_type, :exercise_type]

  validates :placeholder_type, presence: true

  def placeholder?
    true
  end

  def is_correct?
    false
  end

  def completed?
    false
  end

  def can_be_auto_graded?
    true
  end
end

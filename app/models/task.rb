class Task < ActiveRecord::Base
  belongs_to :taskable, polymorphic: true
  belongs_to :details, polymorphic: true

  def is_shared
    assignments.size > 0
  end
end

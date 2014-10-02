class AssignedTask < ActiveRecord::Base
  belongs_to :assignee, polymorphic: true
  belongs_to :task, counter_cache: true
end

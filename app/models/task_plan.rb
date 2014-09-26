class TaskPlan < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  belongs_to :details, polymorphic: true
end

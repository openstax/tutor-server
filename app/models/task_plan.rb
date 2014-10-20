class TaskPlan < ActiveRecord::Base

  belongs_to :owner, polymorphic: true
  belongs_to :details, polymorphic: true

  has_many :tasks

  scope :due, lambda {
    time = Time.now
    includes(:tasks).references(:tasks)
      .where{assign_after < time}.where(task: {id: nil})
  }

end

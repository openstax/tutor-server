class Assistant < ActiveRecord::Base
  belongs_to :study

  has_many :task_plans, dependent: :destroy

  validates :code_class_name, presence: true
end

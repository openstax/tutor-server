class Assistant < ActiveRecord::Base
  belongs_to :study
  has_many :task_plans, dependent: :destroy

  serialize :settings
  serialize :data

  after_initialize :set_attribute_defaults

  validates :code_class_name, presence: true
  validate :code_class_existence

  # Delegate all real work to the actual implementation (the "worker")

  def get_task_plan_types
    worker.get_task_plan_types
  end

  def new_task_plan(type)
    worker.new_task_plan(type).tap do |task_plan|
      task_plan.assistant = self
    end
  end

  def create_and_distribute_tasks(task_plan)
    worker.create_and_distribute_tasks(task_plan)
  end

  protected

  def worker
    @worker ||= code_class.new(settings: settings, data: data)
  end

  def set_attribute_defaults
    self.settings ||= {}
    self.data ||= {}
  end

  def code_class_existence
    !!code_class rescue errors.add(:code_class_name, " doesn't exist"); false
  end

  def code_class
    Kernel.const_get(code_class_name)
  end

end

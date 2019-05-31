class Tasks::Models::Assistant < IndestructibleRecord

  has_many :course_assistants, dependent: :destroy

  has_many :task_plans, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :code_class_name, presence: true, uniqueness: true
  validate :code_class_existence, if: :code_class_name

  # Delegate all real work to the actual implementation (the "worker")
  delegate :schema, to: :code_class

  def build_tasks(task_plan:, individualized_tasking_plans:)
    code_class.new(
      task_plan: task_plan, individualized_tasking_plans: individualized_tasking_plans
    ).build_tasks
  end

  protected

  def code_class_existence
    begin
      code_class
    rescue NameError => e
      errors.add("#{code_class_name} does not exist")
      throw :abort
    end
  end

  def code_class
    @code_class ||= Kernel.const_get(code_class_name)
  end

end

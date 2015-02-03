class Resource < ActiveRecord::Base
  
  has_many :task_steps, dependent: :destroy

  validates :url, uniqueness: true

  def destroy
    # Resources are shared between many task_steps,
    # so only delete if none of those exist anymore.
    return unless task_steps.empty?
    super
  end

  def delete
    destroy
  end

end

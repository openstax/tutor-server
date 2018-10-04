class Research::Models::Brain < ApplicationRecord
  belongs_to :cohort, inverse_of: :brains

  enum domain: { student_task: 1 }

  validates :name, :domain, presence: true
  validate :ensure_valid_hook_for_domain

  VALID_HOOKS = {
    student_task: %i{display update}
  }

  def evaluate(binding)
    begin
      eval(code, binding)
      nil
    rescue Exception => e
      # "rescue exception is evil" is true but this is using one evil to cancel another
      # The eval code should never crash the server
      return e
    end
  end

  protected

  def ensure_valid_hook_for_domain
    if hook.present? && !VALID_HOOKS[domain.to_sym].include?(hook.to_sym)
      errors.add(:hook, "is not valid for domain '#{domain}'")
    end
  end
end

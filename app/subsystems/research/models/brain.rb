class Research::Models::Brain < ApplicationRecord
  belongs_to :cohort, inverse_of: :brains

  enum domain: { student_task: 1 }

  validates :name, :domain, presence: true
  validate :ensure_valid_hook_for_domain

  VALID_HOOKS = {
    student_task: %i{display}
  }

  def evaluate(binding)
    eval(code, binding)
  end

  protected

  def ensure_valid_hook_for_domain
    if hook.present? && !VALID_HOOKS[domain.to_sym].include?(hook.to_sym)
      errors.add(:hook, "is not valid for domain '#{domain}'")
    end
  end
end

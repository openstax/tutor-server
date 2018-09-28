class Research::Models::Brain < ApplicationRecord
  belongs_to :cohort, inverse_of: :brains

  enum subject_area: { student_task: 1 }

  def evaluate(binding)
    eval(code, binding)
  end

end

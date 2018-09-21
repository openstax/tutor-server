class Research::Models::Brain < ApplicationRecord
  belongs_to :study, inverse_of: :brains

  enum subject_area: {
         task_steps: 1,
       }


  def evaluate(binding)
    eval(code, binding)
  end
end

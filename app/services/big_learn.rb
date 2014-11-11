module BigLearn

  mattr_accessor :use_stubs
  self.use_stubs = true

  def self.projection_next_questions(allowed_exercise_definitions:, learner:, count:, difficulty: 0.5)
    if use_stubs
      allowed_exercise_definitions.shuffle[0..count-1]
    else
      raise NotYetImplemented
    end
  end

end
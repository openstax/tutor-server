class Content::GetExercise

  lev_routine express_output: :exercise

  protected

  def exec(id:)
    ex = Content::Models::Exercise.find(id)
    outputs[:exercise] = Exercise.new(ex)
  end

end

class Content::GetExercise

  lev_routine

  protected

  def exec(id:)
    ex = Content::Models::Exercise.find(id)
    outputs[:exercise] = OpenStax::Exercises::V1::Exercise.new(ex.content)
  end

end

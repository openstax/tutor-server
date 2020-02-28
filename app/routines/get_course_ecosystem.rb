class GetCourseEcosystem
  lev_routine transaction: :no_transaction, express_output: :ecosystem

  protected

  def exec(course:)
    outputs.ecosystem = course.ecosystem
  end
end

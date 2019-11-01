class Stats::Calculate
  lev_routine

  CALCULATIONS = %w[
    ActiveCourses
    ActiveStudents
  ].map do |name|
    klass = Stats::Calculations.const_get(name)
    key = name.tableize.to_sym
    uses_routine klass, as: key, translations: { outputs: {
      type: :verbatim
    } }
    key
  end

  protected

  def exec(date_range:)
    CALCULATIONS.each do |calculation|
      run(calculation, courses: outputs.active_courses.dup, date_range: date_range)
    end
  end
end

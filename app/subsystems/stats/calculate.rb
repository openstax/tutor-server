class Stats::Calculate
  lev_routine

  CALCULATIONS = %w[
    Courses
    Students
    Highlights
    Assignments
    Exercises
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
    stats = outputs
    CALCULATIONS.each do |calculation|
      run(calculation, stats: stats, date_range: date_range)
      stats = outputs
    end
  end
end

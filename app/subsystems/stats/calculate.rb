module Stats

  class Calculate
    lev_routine express_output: :interval

    CALCULATIONS = %w[
      Courses
      Users
      Highlights
      Assignments
      Exercises
    ].map { |name|
      klass = Stats::Calculations.const_get(name)
      key = name.tableize.to_sym
      uses_routine klass, as: key, translations: { outputs: { type: :verbatim } }
      key
    }

    protected

    def exec(date_range:)
      outputs.interval = Stats::Models::Interval.new(
        starts_at: date_range.first, ends_at: date_range.last
      )
      CALCULATIONS.each do |calculation|
        run(calculation, interval: outputs.interval)
      end
    end
  end
end

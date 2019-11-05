module Stats

  class Calculate
    lev_routine

    CALCULATIONS = %w[
      Courses
      Students
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
      outputs.interval.save
      transfer_errors_from(outputs.interval, { type: :verbatim }, true)
    end
  end
end

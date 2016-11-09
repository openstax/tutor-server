# Methods in this class are available inside ERB blocks in the YAML file
class Demo::ContentConfigurationYamlMethods

    attr_reader :noon_today

    def initialize
      @noon_today = Time.current.noon
    end

    def get_binding
      binding
    end

    def school_day_on_or_before(time)
      time = time.yesterday while time.sunday? || time.saturday?
      time
    end

    def school_day_on_or_after(time)
      time = time.tomorrow while time.sunday? || time.saturday?
      time
    end

    def today
      @noon_today
    end

    def standard_opens_at(time)
      time.midnight + 1.minute
    end

    def standard_due_at(time)
      time.midnight + 7.hours
    end

    # opens methods
    def open_today
      standard_opens_at(school_day_on_or_before(today))
    end

    # opens in past
    def open_yesterday
      open_one_day_ago
    end

    def open_last_monday
      standard_opens_at(today.monday)
    end

    def open_next_monday
      standard_opens_at(today.monday + 1.week)
    end

    def open_one_day_ago
      standard_opens_at(school_day_on_or_before(today - 1.day))
    end

    def open_two_days_ago
      standard_opens_at(school_day_on_or_before(today - 2.days))
    end

    def open_three_days_ago
      standard_opens_at(school_day_on_or_before(today - 3.days))
    end

    # opens in future
    def open_tomorrow
      open_one_day_from_now
    end

    def open_one_day_from_now
      standard_opens_at(school_day_on_or_after(1.day.from_now))
    end

    def open_two_days_from_now
      standard_opens_at(school_day_on_or_after(2.day.from_now))
    end

    def open_three_days_from_now
      standard_opens_at(school_day_on_or_after(3.day.from_now))
    end


    # due methods
    def due_today
      standard_due_at(today)
    end

    def due_last_monday
      standard_due_at(today.monday)
    end

    def due_next_monday
      standard_due_at(today.monday + 1.week)
    end

    # due in past
    def due_yesterday
      due_one_day_ago
    end

    def due_one_day_ago
      standard_due_at(school_day_on_or_before(today - 1.day))
    end

    def due_two_days_ago
      standard_due_at(school_day_on_or_before(today - 2.days))
    end

    def due_three_days_ago
      standard_due_at(school_day_on_or_before(today - 3.days))
    end

    # due in future
    def due_tomorrow
      standard_due_at(school_day_on_or_after(today + 1.day))
    end

    def due_two_days_from_now
      standard_due_at(school_day_on_or_after(today + 2.days))
    end

    def due_three_days_from_now
      standard_due_at(school_day_on_or_after(today + 3.days))
    end

end

# Instructor picks term and year
# Dates using year depend on the year chosen by the instructor
# Dates using Time.current or DateTime.current depend on the course creation date
# Times here should be UTC, so use DateTime.parse rather than Time.parse
TermYear = Struct.new(:term, :year) do
  const_set 'LEGACY_TERM_STARTS_AT', DateTime.parse('July 1st, 2015')
  const_set 'LEGACY_TERM_ENDS_AT'  , DateTime.parse('Jan 1st, 2017' )

  const_set 'TERM_START_DATES', {
    legacy:  ->(year) { TermYear::LEGACY_TERM_STARTS_AT   },
    demo:    ->(year) { DateTime.new(year - 1, 7 )        }, # July 1st of the year before
    preview: ->(year) { DateTime.current.monday - 2.weeks }, # 2 weeks before the previous monday
    winter:  ->(year) { DateTime.new(year    , 11)        }, # November 1st of given year
    spring:  ->(year) { DateTime.new(year        )        }, # January 1st of given year
    summer:  ->(year) { DateTime.new(year    , 5 )        }, # May 1st of given year
    fall:    ->(year) { DateTime.new(year    , 7 )        }  # July 1st of given year
  }

  const_set 'TERM_END_DATES', {
    legacy:  ->(year) { TermYear::LEGACY_TERM_ENDS_AT     },
    demo:    ->(year) { DateTime.new(year + 1, 6, 30)     }, # June 30th of the year after
    preview: ->(year) { DateTime.current + 8.weeks        }, # 8 weeks after today
    winter:  ->(year) { DateTime.new(year + 1, 3    )     }, # March 1st of next year
    spring:  ->(year) { DateTime.new(year    , 6, 30)     }, # June 30th of given year
    summer:  ->(year) { DateTime.new(year    , 9    )     }, # September 1st of given year
    fall:    ->(year) { DateTime.new(year + 1       )     }  # January 1st of the year after
  }

  const_set 'VISIBLE_TERMS', [:spring, :summer, :fall, :winter]

  attr_reader :starts_at, :ends_at

  def initialize(term, year)
    year_int = Integer(year) rescue raise(ArgumentError, "Invalid year: #{year}", caller)

    term_sym = term.to_sym
    start_proc = TermYear::TERM_START_DATES[term_sym]
    end_proc = TermYear::TERM_END_DATES[term_sym]

    raise(ArgumentError, "Invalid term: #{term}", caller) if start_proc.nil? || end_proc.nil?

    super(term_sym, year_int)

    @starts_at = start_proc.call(year)
    @ends_at   = end_proc.call(year) - 1.second
  end

  def self.visible_term_years(current_time = Time.current)
    current_year = current_time.year

    current_year_visible_term_years = TermYear::VISIBLE_TERMS.map do |term|
      TermYear.new(term, current_year)
    end.select{ |term_year| term_year.ends_at > current_time }

    next_year_visible_term_years = TermYear::VISIBLE_TERMS.map do |term|
      TermYear.new(term, current_year + 1)
    end.select{ |term_year| term_year.ends_at <= current_time + 1.year }

    current_year_visible_term_years + next_year_visible_term_years
  end
end

TermYear = Struct.new(:term, :year) do
  LEGACY_TERM_STARTS_AT = DateTime.parse('July 1st, 2015')
  LEGACY_TERM_ENDS_AT   = DateTime.parse('Feb 1st, 2017' )

  TERM_START_DATES = {
    legacy: ->(year) { LEGACY_TERM_STARTS_AT                  },
    demo:   ->(year) { DateTime.new(Time.current.year - 1, 7) }, # July 1st of last year
    spring: ->(year) { DateTime.new(             year       ) }, # January 1st of given year
    summer: ->(year) { DateTime.new(             year    , 5) }, # May 1st of given year
    fall:   ->(year) { DateTime.new(             year    , 7) }  # July 1st of given year
  }

  TERM_END_DATES = {
    legacy: ->(year) { LEGACY_TERM_ENDS_AT                    },
    demo:   ->(year) { DateTime.new(Time.current.year + 1, 7) }, # July 1st of next year
    spring: ->(year) { DateTime.new(             year    , 7) }, # July 1st of given year
    summer: ->(year) { DateTime.new(             year    , 9) }, # September 1st of given year
    fall:   ->(year) { DateTime.new(             year + 1   ) }  # January 1st of the year
                                                                 # after given year
  }

  VISIBLE_TERMS = [:spring, :summer, :fall]

  attr_reader :starts_at, :ends_at

  def initialize(term, year)
    year_int = Integer(year) rescue raise(ArgumentError, "Invalid year: #{year}", caller)

    term_sym = term.to_sym
    start_proc = TERM_START_DATES[term_sym]
    end_proc = TERM_END_DATES[term_sym]

    raise(ArgumentError, "Invalid term: #{term}", caller) if start_proc.nil? || end_proc.nil?

    super(term_sym, year_int)

    @starts_at = start_proc.call(year)
    @ends_at   = end_proc.call(year) - 1.second
  end

  def self.visible_term_years(current_time = Time.current)
    current_year = current_time.year

    current_year_visible_term_years = VISIBLE_TERMS.map do |term|
      TermYear.new(term, current_year)
    end.select{ |term_year| term_year.ends_at > current_time }

    next_year_visible_term_years = VISIBLE_TERMS.map do |term|
      TermYear.new(term, current_year + 1)
    end.select{ |term_year| term_year.starts_at <= current_time + 1.year }

    current_year_visible_term_years + next_year_visible_term_years
  end
end

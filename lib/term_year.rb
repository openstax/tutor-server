class TermYear
  LEGACY_TERM_STARTS_AT = DateTime.parse('July 1st, 2015')
  LEGACY_TERM_ENDS_AT   = DateTime.parse('July 1st, 2017')

  TERM_START_DATES = {
    legacy: ->(year) { LEGACY_TERM_STARTS_AT },
    demo:   ->(year) { DateTime.new(year   ) },  # January 1st of the year
    spring: ->(year) { DateTime.new(year   ) },  # January 1st of the year
    summer: ->(year) { DateTime.new(year, 5) },  # May 1st of the year
    fall:   ->(year) { DateTime.new(year, 7) }   # July 1st of the year
  }

  TERM_END_DATES = {
    legacy: ->(year) { LEGACY_TERM_ENDS_AT },
    demo:   ->(year) { DateTime.new(year + 1) }, # January 1st of next year
    spring: ->(year) { DateTime.new(year, 7 ) }, # July 1st of the year
    summer: ->(year) { DateTime.new(year, 9 ) }, # September 1st of the year
    fall:   ->(year) { DateTime.new(year + 1) }  # January 1st of next year
  }

  attr_reader :starts_at, :ends_at

  def initialize(term, year)
    term_sym = term.to_sym
    start_proc = TERM_START_DATES[term_sym]
    end_proc = TERM_END_DATES[term_sym]

    raise ArgumentError, "Invalid term: #{term}", caller if start_proc.nil? || end_proc.nil?

    @starts_at = start_proc.call(year)
    @ends_at   = end_proc.call(year) - 1.second
  end
end

class Salesforce::Remote::TermYear

  # TermYear strings in Salesforce look like:
  #   2015 - 16 Fall
  #   2015 - 16 Spring
  # One day in the not-distant future we will probably be adding Summerlas term

  TERMS = [:fall, :spring]

  attr_reader :start_year, :end_year, :term

  def initialize(start_year:, term:)
    raise "Invalid term #{term}" if !TERMS.include?(term)
    @start_year = start_year
    @end_year = [:fall, :spring].include?(term) ? start_year + 1 : start_year
    @term = term
  end

  def self.guess_from_created_at(created_at)
    spring_to_fall_cutoff = Time.zone.local(created_at.year, 4, 15, 00, 00)
    fall_to_spring_cutoff = Time.zone.local(created_at.year, 11, 15, 00, 00)

    if created_at < spring_to_fall_cutoff
      new(start_year: created_at.year - 1, term: :spring)
    elsif created_at > fall_to_spring_cutoff
      new(start_year: created_at.year, term: :spring)
    else
      new(start_year: created_at.year, term: :fall)
    end
  end

  def self.from_string(string)
    string.match(/20(\d\d) - (\d\d) (\w+)/).tap do |match|
      raise(ParseError, "Cannot parse '#{string}' as a TermYear") if match.nil?
    end

    term = $3.downcase.to_sym
    start_year = "20#{$1}".to_i
    raise "Non-sequential years in TermYear: '#{string}'" if $2.to_i != $1.to_i + 1

    new(start_year: start_year, term: term)
  end

  def next
    fall? ?
      self.class.new(start_year: start_year, term: :spring) :
      self.class.new(start_year: start_year + 1, term: :fall)
  end

  def to_s
    "#{start_year} - #{end_year.to_s[2..3]} #{fall? ? 'Fall' : 'Spring'}"
  end

  def fall?
    :fall == @term
  end

  def spring?
    !fall?
  end

  def ==(other)
    to_s == other.to_s
  end

  def eql?(other)
    self == other
  end

  def dup
    self.class.new(start_year: start_year, term: term)
  end

  class ParseError < StandardError; end

end

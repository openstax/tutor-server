class Stats::Calculations::Highlights
  lev_routine

  protected

  def exec(interval:)
    highlights = Content::Models::Note.where(:created_at => interval.range)
    interval.stats['highlights'] = highlights.dup.count
    interval.stats['notes'] = highlights.where("annotation != ''").count
  end

end

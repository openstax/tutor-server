class Stats::Calculations::Highlights
  lev_routine

  protected

  def exec(interval:)
    nt = Content::Models::Note.arel_table
    highlights = Content::Models::Note.where(nt[:created_at].lteq(interval.ends_at))
    interval.stats['highlights'] = highlights.dup.count
    interval.stats['notes'] = highlights.where("annotation != ''").count

    highlights = Content::Models::Note.where(:created_at => interval.range)
    interval.stats['new_highlights'] = highlights.dup.count
    interval.stats['new_notes'] = highlights.where("annotation != ''").count
  end

end

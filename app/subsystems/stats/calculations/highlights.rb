class Stats::Calculations::Highlights
  lev_routine

  protected

  def exec(stats:, date_range:)
    highlights = Content::Models::Note.where(:created_at => date_range)

    outputs.num_highlights = highlights.dup.count
    outputs.num_notes = highlights.where("annotation != ''").count
  end

end

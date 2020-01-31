module Stats

  class Generate

    START_DATE = DateTime.parse('2016-06-01').beginning_of_week

    lev_routine

    uses_routine Calculate, translations: { outputs: { type: :verbatim } }

    protected

    def exec(start_at: START_DATE)
      end_at = (start_at + 1.week)
      Stats::Models::Interval.transaction do
        st = Stats::Models::Interval.arel_table
        Stats::Models::Interval.where(st[:starts_at].gt(start_at)).delete_all
        while end_at < Date.tomorrow
          date_range = (start_at...end_at)
          stats = Calculate[date_range: date_range]
          stats.save! unless stats.empty?
          start_at = end_at
          end_at = (end_at + 1.week).end_of_week
        end
      end
    end
  end
end

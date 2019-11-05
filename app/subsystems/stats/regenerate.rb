module Stats

  class Regenerate

    START_DATE = DateTime.parse('2016-06-01').beginning_of_week

    lev_routine

    uses_routine Calculate, as: :calculate, translations: { outputs: { type: :verbatim } }

    protected

    def exec(start_at: START_DATE)
      end_at = (start_at + 1.week)
      Stats::Models::Interval.transaction do
        st = Stats::Models::Interval.arel_table
        Stats::Models::Interval.where(st[:starts_at].lt(start_at)).delete_all
        while end_at < Date.today
          date_range = (start_at...end_at)
          run :calculate, date_range: date_range
          start_at = end_at
          end_at = (end_at + 1.week).end_of_week
        end
      end
    end
  end
end

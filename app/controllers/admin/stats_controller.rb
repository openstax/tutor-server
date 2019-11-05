class Admin::StatsController < Admin::BaseController

  def stats
    render json: Stats::Models::Interval.order(:starts_at).except(:id)
  end

end

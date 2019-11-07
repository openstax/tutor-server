class Api::V1::StatsController < Admin::BaseController # the Admin controller enforces admin role

  def stats
    render json: Stats::Models::Interval.order(:starts_at).except(:id)
  end

end

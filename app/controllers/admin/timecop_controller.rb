class Admin::TimecopController < Admin::BaseController
  before_filter :timecop_enabled

  def timecop
  end

  def reset_time
    Timecop.return_all
    redirect_to admin_timecop_path
  end

  def time_travel
    Timecop.return_all
    new_time_in_zone = timestr_and_zonestr_to_utc_time(params[:new_time], params[:time_zone])
    Timecop.travel_all(new_time_in_zone)
    redirect_to admin_timecop_path
  end

  protected

  def timecop_enabled
    Timecop.enabled? || head(:not_found)
  end

  def timestr_and_zonestr_to_utc_time(time_str, time_zone_str)
    time = Chronic.parse(time_str)
    raise "Unable to parse time: #{time_str}" if time.nil?
    zone = ActiveSupport::TimeZone.new(time_zone_str)
    raise "Unable to parse time_zone: #{time_zone_str}" if zone.nil?
    zone.local_to_utc(time)
  end
end

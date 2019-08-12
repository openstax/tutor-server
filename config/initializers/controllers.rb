ActionController::Base.class_exec do
  helper ApplicationHelper

  around_action :set_app_date_time

  # skip setting regular date header and don't raise exception if the callback hasn't been set
  skip_after_action :set_date_header, raise: false

  protected

  def consumed(representer, **options)
    opts = { new_record?: true, persisted?: false }.merge(options)

    OpenStruct.new(opts).tap do |hash|
      consume!(hash, represent_with: representer)
    end.marshal_dump.except(*opts.keys)
  end

  def set_app_date_time
    time_header = request.headers['X-App-Date']
    if IAm.real_production? || time_header.blank?
      yield
      set_app_date_header
      return
    end

    begin
      time = DateTime.parse time_header
    rescue ArgumentError
      render plain: 'Invalid X-App-Date header', status: :bad_request
      set_app_date_header
    else
      Time.use_zone(time.utc_offset) do
        Timecop.travel(time) do
          yield
          set_app_date_header
        end
      end
    end
  end

  def set_app_date_header
    response.headers['X-App-Date'] ||= Time.current.httpdate
  end
end

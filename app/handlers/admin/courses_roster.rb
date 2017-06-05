class Admin::CoursesRoster

  lev_handler

  protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :blank_period, message: "You must select a period to upload to.") \
      if params[:period].nil?

    fatal_error(code: :blank_file, message: "You must attach a file to upload.") \
      if params[:roster].nil?

    period = CourseMembership::Models::Period.find_by(
      id: params[:period], course_profile_course_id: params[:id]
    )

    fatal_error(code: :invalid_period, message: "The selected period could not be found.") \
      if period.nil?

    csv_reader = CSV.new(params[:roster].to_io, headers: true)

    parse_errors = []
    user_hashes = csv_reader.map do |row|
      parse_errors.concat validate_csv_row(row, csv_reader.lineno)
      row.to_h.slice('username', 'password', 'first_name', 'last_name').symbolize_keys
    end

    fatal_error(code: :parse_errors, message: parse_errors) unless parse_errors.empty?

    ImportRoster.perform_later user_hashes: user_hashes, period: period
  rescue CSV::MalformedCSVError => e
    fatal_error(code: :malformed_csv, message: e.message)
  end

  def validate_csv_row(row, lineno)
    [].tap do |errors|
      [ :username, :password ].each do |attr|
        errors << "Invalid Roster: On line #{lineno}, #{attr} is missing." if row[attr.to_s].blank?
      end
    end
  end

end

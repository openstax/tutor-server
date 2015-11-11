class Admin::CoursesStudents
  lev_handler

  uses_routine AddUserAsPeriodStudent
  uses_routine User::FindOrCreateUser, as: :find_or_create_user,
                                       translations: { outputs: { type: :verbatim } }

  protected
  def authorized?; true; end

  def handle
    if params[:student_roster].present?
      add_students_from_roster_file
    else
      fatal_error(code: :blank_file, message: "You must attach a file to upload.")
    end
  end

  private
  def add_students_from_roster_file
    begin
      parse_attributes_from_roster_file
    rescue CSV::MalformedCSVError => e
      fatal_error(code: :malformed_csv, message: e.message)
    end
  end

  def parse_attributes_from_roster_file
    period = CourseMembership::Models::Period.find(params[:course][:period])
    csv_reader = CSV.new(params[:student_roster].read, headers: true)
    parse_errors = []

    csv_reader.each do |row|
      parse_errors << validate_csv_row(row, csv_reader.lineno, :username)
      parse_errors << validate_csv_row(row, csv_reader.lineno, :password)
      parse_errors.compact!
      next if parse_errors.any?

      user = run(:find_or_create_user, username: row['username'],
                                       password: row['password'],
                                       first_name: row['first_name'],
                                       last_name: row['last_name']).outputs.user

      run(:add_user_as_period_student, period: period, user: user)
    end

    fatal_error(code: :parse_errors, message: parse_errors) if parse_errors.any?
  end

  def validate_csv_row(row, lineno, attr)
    "On line #{lineno}, #{attr} is missing." if row[attr.to_s].blank?
  end
end

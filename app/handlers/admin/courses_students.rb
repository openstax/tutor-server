class Admin::CoursesStudents
  lev_handler

  protected
  def authorized?; true; end

  def handle
    outputs.period = CourseMembership::Models::Period.find(params[:course][:period])
    outputs.users_attributes = []

    if params[:student_roster].blank?
      fatal_error(code: :no_file_attached, message: 'You must attach a file to upload.')
    end

    begin
      csv_reader = CSV.new(params[:student_roster].read, headers: true)

      csv_reader.each do |row|
        outputs.users_attributes << row

        unless row['username'].present?
          nonfatal_error(code: :username_missing,
                      message: "On line #{csv_reader.lineno}, username is missing.")
        end

        unless row['password'].present?
          nonfatal_error(code: :password_missing,
                      message: "On line #{csv_reader.lineno}, password is missing.")
        end
      end
    rescue CSV::MalformedCSVError => e
      nonfatal_error(code: :malformed_csv, message: e.message)
    end

    if errors.any?
      errors.insert(0, Lev::Error.new(code: :error_uploading,
                                      message: 'Error uploading student roster'))
      fatal_error(code: :fatal_errors)
    end
  end
end

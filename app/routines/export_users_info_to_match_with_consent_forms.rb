class ExportUsersInfoToMatchWithConsentForms
  lev_routine express_output: :filename

  def exec(delete_after: true)
    outputs[:filename] = filename
    outputs[:info] = info
    generate_csv
    remove_exported_files if delete_after
  end

  def info
    output_users = []
    User::Models::Profile.with_deleted.joins(:account).find_each do |user|
      output_users << Hashie::Mash.new({
        user_id: user.account.openstax_uid,
        student_identifiers: user.roles.map(&:student).compact.map(&:student_identifier),
        name: user.name,
        username: user.username
      })
    end
    output_users
  end

  def generate_csv
    CSV.open(filename, 'w') do |file|
      file.add_row ([
        "User ID",
        "Student Identifiers",
        "Name",
        "Username"
      ])

      info.each do |hashie|
        file.add_row([
          hashie.user_id,
          hashie.student_identifiers.join(", "),
          hashie.name,
          hashie.username
        ])
      end
    end
  end

  def filename
    File.join exports_folder, "users_info_to_match_with_consent_forms.csv"
  end

  def exports_folder
    File.join 'tmp', 'exports'
  end

  def remove_exported_files
    File.delete(filename) if File.exist?(filename)
  end
end

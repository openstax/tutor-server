require 'pgdb'
require 'open3'

class Research::ExportData

  lev_routine

  # these tables either contain PII,
  # or have a foreign key that depends on one that does
  EXCLUDED_TABLES=%w{
   user_profiles openstax_accounts*
   lms_course_score_callbacks
   user_administrators
   user_tour_views
   role_role_users
   user_researchers
   course_membership_enrollment_changes
   user_content_analysts
   user_customer_services
  }

  def exec
    cmd = "pg_dump --clean #{Pgdb.cmd_line_flags.join(' ')}"
    EXCLUDED_TABLES.each{|table|
      cmd << ' --exclude-table '
      cmd << table
    }
    cmd << " #{Pgdb.name}"
    cmd << " | psql --quiet --output /dev/null #{Rails.application.secrets.research_db_connection}"

    output, status = Open3.capture2e(Pgdb.env, cmd)
    outputs.output = output

    unless status.success?
      fatal_error(code: :command_failed, message: "#{cmd} failed with #{output}")
    end
  end

end

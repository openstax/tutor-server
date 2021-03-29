namespace :cron do
  task month: :log_to_stdout do
    Rails.logger.debug 'Starting monthly cron'

    Rails.logger.info 'Tasks::FreezeEndedCourseTeacherPerformanceReports.call'
    OpenStax::RescueFrom.this { Tasks::FreezeEndedCourseTeacherPerformanceReports.call }

    Rails.logger.info 'Jobba.cleanup'
    OpenStax::RescueFrom.this { Jobba.cleanup }

    Rails.logger.debug 'Finished monthly cron'
  end
end

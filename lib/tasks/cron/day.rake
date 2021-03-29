namespace :cron do
  task day: :log_to_stdout do
    Rails.logger.debug 'Starting daily cron'

    Rails.logger.info 'GetSalesforceBookNames.call true'
    OpenStax::RescueFrom.this { GetSalesforceBookNames.call true }

    Rails.logger.info 'PushSalesforceCourseStats.call'
    OpenStax::RescueFrom.this { PushSalesforceCourseStats.call }

    Rails.logger.info 'Lms::Models::TrustedLaunchData.cleanup'
    OpenStax::RescueFrom.this { Lms::Models::TrustedLaunchData.cleanup }

    Rails.logger.debug 'Finished daily cron'
  end
end

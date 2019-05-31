class Lms::Models::TrustedLaunchData < ApplicationRecord
  # During a launch, we have to send users off to Accounts and back.  This model
  # stores launch data so it can be used when users return from Accounts.

  def self.cleanup
    where(arel_table[:created_at].lt(Time.current - 1.year)).delete_all
  end
end

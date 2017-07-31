class Lms::Models::TrustedLaunchData < ApplicationRecord
  # During a launch, we have to send users off to Accounts and back.  This model
  # stores launch data so it can be used when users return from Accounts.
end

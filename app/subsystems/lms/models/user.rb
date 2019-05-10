class Lms::Models::User < ApplicationRecord
  belongs_to :account,
             class_name: 'OpenStax::Accounts::Account',
             subsystem: 'none',
             optional: true
end

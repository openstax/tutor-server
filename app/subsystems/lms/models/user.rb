class Lms::Models::User < Tutor::SubSystems::BaseModel

  belongs_to :account,
             class_name: 'OpenStax::Accounts::Account',
             subsystem: 'none'
end

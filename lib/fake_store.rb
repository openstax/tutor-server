return if !Rails.env.production?

# This class is used to mimic a remote database.  When the fake versions of our
# app/external clients need to persist data, they store it in one of these objects
# as serialized data.

class FakeStore < ActiveRecord::Base
  serialize :store

  validates :name, presence: true, uniqueness: true
end
# ActiveJob has a memory leak if you queue a job inside another job.
# This monkeypatch is a workaround.
# Original issue: https://github.com/rails/rails/issues/21036
# Monkeypatches:
# https://github.com/thoughtbot/suspenders/commit/38b530c0a6a86175791c95a8f793d31b07b97c2d
# https://github.com/alphagov/e-petitions/commit/e26f4a63bec76a0fe1c7512d247a9b73e4c19132
require 'active_job/logging'

ActiveSupport::Notifications.unsubscribe 'enqueue.active_job'
ActiveSupport::Notifications.unsubscribe 'enqueue_at.active_job'

module ActiveJob
  module Logging
    class EnqueueLogSubscriber < LogSubscriber
      define_method :enqueue, instance_method(:enqueue)
      define_method :enqueue_at, instance_method(:enqueue_at)
    end
  end
end

ActiveJob::Logging::EnqueueLogSubscriber.attach_to :active_job

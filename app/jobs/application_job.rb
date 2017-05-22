class ApplicationJob < ActiveJob::Base
  def self.perform(*args)
    new.perform(*args)
  end
end

class OpenStax::Biglearn::Api::Job < ActiveJob::Base
  queue_as :default

  def perform(method, requests)
    OpenStax::Biglearn::Api.client.public_send method, requests
  end
end

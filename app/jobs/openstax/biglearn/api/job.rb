class OpenStax::Biglearn::Api::Job < ApplicationJob
  queue_as :default

  def perform(method:, requests:, **ignored)
    OpenStax::Biglearn::Api.client.public_send(method, requests)
  end
end

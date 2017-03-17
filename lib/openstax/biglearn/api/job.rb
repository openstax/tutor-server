class OpenStax::Biglearn::Api::Job < ActiveJob::Base
  queue_as :default

  def perform(method, requests, retry_proc)
    response = OpenStax::Biglearn::Api.client.public_send(method, requests)

    raise OpenStax::Biglearn::Api::JobFailed if retry_proc.present? && retry_proc.call(response)
  end
end

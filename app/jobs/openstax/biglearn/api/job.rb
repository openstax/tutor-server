class OpenStax::Biglearn::Api::Job < ApplicationJob
  queue_as :default

  def perform(method:, requests:, response_status_key: nil, accepted_response_status: [], **ignored)
    OpenStax::Biglearn::Api.client.public_send(method, requests).tap do |response|
      next if response_status_key.nil?

      response_status_key = response_status_key.to_sym
      accepted_response_status = [accepted_response_status].flatten
      responses = [response].flatten

      responses.each do |response|
        raise OpenStax::Biglearn::Api::JobFailed \
          if !accepted_response_status.include?(response[response_status_key])
      end
    end
  end
end

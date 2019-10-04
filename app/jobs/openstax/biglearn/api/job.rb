class OpenStax::Biglearn::Api::Job < ApplicationJob
  queue_as :biglearn

  def perform(method:, requests:, response_status_key: nil, accepted_response_status: [], **ignored)
    OpenStax::Biglearn::Api.client.public_send(method, requests).tap do |response|
      next if response_status_key.nil?

      response_status_key = response_status_key.to_sym
      accepted_response_status = [accepted_response_status].flatten
      responses = [response].flatten

      responses.each do |response|
        raise(
          OpenStax::Biglearn::Api::JobFailed,
          "[#{method}] Expected \"#{response_status_key}\" to be in #{
          accepted_response_status.inspect} but was \"#{response[response_status_key]}\" instead"
        ) unless accepted_response_status.include?(response[response_status_key])
      end
    end
  end
end

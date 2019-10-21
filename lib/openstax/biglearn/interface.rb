module OpenStax::Biglearn::Interface
  def self.included(base)
    base.extend Configurable
    base.extend Configurable::ClientMethods
    base.extend MonitorMixin
  end

  def verify_and_slice_request(method:, request:, keys:, optional_keys: [])
    required_keys = [keys].flatten
    missing_keys = required_keys.reject { |key| request.has_key? key }

    raise(
      OpenStax::Biglearn::MalformedRequest,
      "Invalid request: #{method} request #{request.inspect
      } is missing these required key(s): #{missing_keys.inspect}"
    ) if missing_keys.any?

    optional_keys = [optional_keys].flatten
    request_keys = required_keys + optional_keys

    request.slice(*request_keys)
  end

  def verify_result(result:, result_class: Hash)
    results_array = [result].flatten

    results_array.each do |result|
      raise(
        OpenStax::Biglearn::ResultTypeError,
        "Invalid result: #{result} has type #{result.class.name
        } but expected type was #{result_class.name}"
      ) if result.class != result_class
    end

    result
  end
end

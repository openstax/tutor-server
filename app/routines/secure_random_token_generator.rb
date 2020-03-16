class UnhandledTokenGeneratorMode < StandardError
end

class SecureRandomTokenGenerator
  lev_routine express_output: :token

  def self.handled_modes
    [ :hex, :base64, :urlsafe_base64, :random_number, :uuid ]
  end

  protected

  def exec(mode:, length: nil, padding: nil, prefix: nil, suffix: nil)
    result = case mode.to_sym
    when :hex
      SecureRandom.hex length
    when :base64
      SecureRandom.base64 length
    when :urlsafe_base64
      SecureRandom.urlsafe_base64 length, padding
    when :random_number
      ll = length || 6
      SecureRandom.random_number(10 ** ll).to_s.rjust(ll, '0')
    when :uuid
      SecureRandom.uuid
    else
      raise UnhandledTokenGeneratorMode, mode
    end

    outputs.token = result.is_a?(String) ? "#{prefix}#{result}#{suffix}" : result
  end
end

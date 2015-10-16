module WithoutException
  def rescuing_exceptions(&block)
    original_raise_exceptions = OpenStax::RescueFrom.configuration.raise_exceptions
    begin
      OpenStax::RescueFrom.configuration.raise_exceptions = false
      yield
    ensure
      OpenStax::RescueFrom.configuration.raise_exceptions = original_raise_exceptions
    end
  end
end

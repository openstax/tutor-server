module WithoutException
  def rescuing_exceptions(&block)
    OpenStax::RescueFrom.configure { |c| c.raise_exceptions = false }
    yield
    OpenStax::RescueFrom.configure { |c| c.raise_exceptions = true }
  end
end

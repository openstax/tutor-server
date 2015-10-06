class Admin::ConsoleController < Admin::BaseController

  def test_raise
    type = params[:type] || 'standard_error'
    msg = "Ignore this test exception"

    case type
    when 'record_not_found'
      raise ActiveRecord::RecordNotFound, msg
    when 'argument_error'
      raise ArgumentError, msg
    when 'standard_error'
      raise StandardError, msg
    else
      raise StandardError, msg
    end
  end

end

# For places where openstax_rescue_from isn't automatically used (e.g. cron
# 'runner' calls), this wrapper is a quick way to handle exceptions with
# openstax_rescue_from.
#
# Usage:
#
#   OpenStax::RescueFrom.this{ SomeCodeHereThatCanRaise }

module OpenStax::RescueFrom
  def self.this
    begin
      yield
    rescue Exception => e
      perform_rescue(e)
    end
  end
end

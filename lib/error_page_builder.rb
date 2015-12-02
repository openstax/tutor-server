require 'render_anywhere'

class ErrorPageBuilder
  include RenderAnywhere

  def self.build(code:, heading:)
    new.render template: 'layouts/static_error',
               layout: false,
               locals: {code: code, heading: heading}
  end
end

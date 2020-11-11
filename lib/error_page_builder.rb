require 'render_anywhere'

class ErrorPageBuilder
  include RenderAnywhere

  def self.build(view:, code:, heading:)
    stylesheet_tag = view.stylesheet_link_tag 'application', media: 'all'

    new.render template: 'layouts/static_error',
               layout: false,
               locals: { stylesheet_tag: stylesheet_tag, code: code, heading: heading }
  end
end

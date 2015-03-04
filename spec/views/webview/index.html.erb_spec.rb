require 'rails_helper'

RSpec.describe "webview/index", :type => :view do
  it "renders the webview" do
    render

    expect(rendered).to include("<script type='text/javascript' src='#{Rails.application.secrets[:openstax_tutor_js_url]}' defer></script>")
    expect(rendered).to include("<link rel='stylesheet' href='#{Rails.application.secrets[:openstax_tutor_css_url]}' />")
  end
end

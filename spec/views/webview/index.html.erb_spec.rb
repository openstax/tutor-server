require 'rails_helper'

RSpec.describe "webview/index", type: :view do
  it "does not contain any content" do
    render

    expect(rendered).to be_blank
  end
end

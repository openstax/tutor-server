require 'rails_helper'

RSpec.describe "webview/index", type: :view do
  it "contains the loading animation content" do
    render

    expect(rendered).to include 'boot-splash-screen'
  end
end

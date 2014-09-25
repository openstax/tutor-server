class WebviewController < ApplicationController

  respond_to :html

  layout 'webview'

  def index
    @name = current_user.casual_name
    @path = request.fullpath
  end

end

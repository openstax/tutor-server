class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: :loader

  skip_before_action :verify_authenticity_token, only: :loader

  def loader
    respond_to do |format|
      format.js
    end
  end

end

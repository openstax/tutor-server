class StaticPageController < ApplicationController
  
  skip_interceptor :authenticate_user!, only: [:home, :terms, :copyright, :api]

end

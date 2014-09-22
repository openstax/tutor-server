Rails.application.routes.draw do

  get 'static_page/copyright'
  get 'static_page/api'
  get 'static_page/terms'

  root 'static_page#home'
  
end

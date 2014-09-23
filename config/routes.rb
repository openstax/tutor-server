Rails.application.routes.draw do

  scope module: 'static_pages' do
    root 'home'
    get 'about'
    get 'contact'
    get 'copyright'
    get 'developers'
    get 'help'
    get 'privacy'
    get 'share'
    get 'status'
    get 'tou'
  end

  mount OpenStax::Accounts::Engine, at: "/accounts"
  
end

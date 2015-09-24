require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let!(:admin) {
    profile = FactoryGirl.create :user_profile,
                                 :administrator,
                                 username: 'admin',
                                 full_name: 'Administrator'
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:profile) {
    FactoryGirl.create :user_profile,
                       username: 'student',
                       full_name: 'User One'
  }
  let!(:user) {
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  before { controller.sign_in(admin) }

  it 'searches users by username and full name' do
    get :index, search_term: 'STR'
    expect(assigns[:user_search].items.length).to eq 1
    expect(assigns[:user_search].items).to eq [ admin ]

    get :index, search_term: 'st'
    expect(assigns[:user_search].items.length).to eq 2
    expect(assigns[:user_search].items.sort_by { |a| a.id }).to eq [ admin, user ]
  end

  it 'creates a new user' do
    post :create, user: {
      username: 'new',
      password: 'password',
      first_name: 'New',
      last_name: 'User',
      full_name: 'Overriden!',
      content_analyst: true
    }

    get :index, search_term: 'new'
    expect(assigns[:user_search].items.length).to eq 1
    user = assigns[:user_search].items.first
    expect(user.username).to eq 'new'
    expect(user.first_name).to eq 'New'
    expect(user.last_name).to eq 'User'
    expect(user.name).to eq 'Overriden!'
    expect(user.is_admin?).to eq false
    expect(user.is_content_analyst?).to eq true
  end

  it 'updates a user' do
    put :update, id: user.id, user: {
      username: 'updated',
      full_name: 'Updated Name',
      content_analyst: true
    }

    strategy = ::User::Strategies::Direct::User.new(profile.reload)
    reloaded_user = ::User::User.new(strategy: strategy)

    expect(reloaded_user.username).to eq 'updated'
    expect(reloaded_user.name).to eq 'Updated Name'
    expect(reloaded_user.is_admin?).to eq false
    expect(reloaded_user.is_content_analyst?).to eq true
  end
end

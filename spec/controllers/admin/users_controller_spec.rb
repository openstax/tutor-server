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
  let!(:user) {
    profile = FactoryGirl.create :user_profile,
                                 username: 'student',
                                 full_name: 'User One'
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
    expect(assigns[:user_search].items.first.attributes).to include(
      username: 'new',
      name: 'New User',
      full_name: 'Overriden!',
      is_admin: false,
      is_content_analyst: true)
  end

  it 'updates a user' do
    put :update, id: user.id, user: {
      username: 'updated',
      full_name: 'Updated Name',
      content_analyst: true
    }

    expect(user.reload.username).to eq 'updated'
    expect(user.name).to eq 'Updated Name'
    expect(user.is_admin?).to eq false
    expect(user.is_content_analyst?).to eq true
  end
end

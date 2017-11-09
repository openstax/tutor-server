require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let!(:admin) { FactoryBot.create :user, :administrator,
                                           username: 'admin',
                                           full_name: 'Administrator' }
  let!(:user) { FactoryBot.create :user, username: 'student', full_name: 'User One' }

  before { controller.sign_in(admin) }

  it 'searches users by username and full name' do
    get :index, query: 'STR'
    expect(assigns[:user_search].items.length).to eq 1
    expect(assigns[:user_search].items).to eq [ admin ]

    get :index, query: 'st'
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
      customer_service: true,
      content_analyst: true
    }

    get :index, query: 'new'
    expect(assigns[:user_search].items.length).to eq 1
    user = assigns[:user_search].items.first
    expect(user.username).to eq 'new'
    expect(user.first_name).to eq 'New'
    expect(user.last_name).to eq 'User'
    expect(user.name).to eq 'Overriden!'
    expect(user.is_admin?).to eq false
    expect(user.is_customer_service?).to eq true
    expect(user.is_content_analyst?).to eq true
  end

  it 'updates a user' do
    put :update, id: user.id, user: {
      username: 'updated',
      full_name: 'Updated Name',
      customer_service: true,
      content_analyst: true
    }

    user.to_model.reload

    expect(user.username).to eq 'updated'
    expect(user.name).to eq 'Updated Name'
    expect(user.is_admin?).to eq false
    expect(user.is_customer_service?).to eq true
    expect(user.is_content_analyst?).to eq true
  end
end

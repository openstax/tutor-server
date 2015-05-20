require 'rails_helper'

RSpec.describe Admin::UsersController do
  let!(:admin) { FactoryGirl.create :user_profile,
                                    :administrator,
                                    username: 'admin',
                                    full_name: 'Administrator' }
  let!(:user) { FactoryGirl.create :user_profile,
                                   username: 'student',
                                   full_name: 'User One' }

  before { controller.sign_in(admin) }

  it 'searches users by username and full name' do
    get :index, search_term: 'STR'
    expect(assigns[:users].length).to eq 1
    expect(assigns[:users]).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user.id,
      'full_name' => 'Administrator',
      'username' => 'admin'
    } ]

    get :index, search_term: 'st'
    expect(assigns[:users].length).to eq 2
    expect(assigns[:users].sort_by { |a| a[:id] }).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user.id,
      'full_name' => 'Administrator',
      'username' => 'admin'
    }, {
      'id' => user.id,
      'account_id' => user.account.id,
      'entity_user_id' => user.entity_user.id,
      'full_name' => 'User One',
      'username' => 'student'
    } ]
  end

  it 'creates a new user' do
    post :create, user: {
      username: 'new',
      password: 'password',
      full_name: 'New User'
    }

    get :index, search_term: 'new'
    expect(assigns[:users].length).to eq 1
    expect(assigns[:users].first).to include(
      username: 'new',
      full_name: 'New User')
  end

  it 'updates a user' do
    put :update, id: user.id, user: {
      username: 'updated',
      full_name: 'Updated Name'
    }

    user.reload
    expect(user.username).to eq 'updated'
    expect(user.full_name).to eq 'Updated Name'
  end
end

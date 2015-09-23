require 'rails_helper'

RSpec.describe Admin::UsersController do
  let!(:admin) { FactoryGirl.create :user_profile_profile,
                                    :administrator,
                                    username: 'admin',
                                    full_name: 'Administrator' }
  let!(:profile) { FactoryGirl.create :user_profile_profile,
                                      username: 'student',
                                      full_name: 'User One' }

  before { controller.sign_in(admin) }

  it 'searches users by username and full name' do
    get :index, search_term: 'STR'
    expect(assigns[:user_search].items.length).to eq 1
    expect(assigns[:user_search].items).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user_id,
      'full_name' => 'Administrator',
      'name' => admin.name,
      'username' => 'admin',
      'is_admin' => true,
      'is_content_analyst' => false
    } ]

    get :index, search_term: 'st'
    expect(assigns[:user_search].items.length).to eq 2
    expect(assigns[:user_search].items.sort_by { |a| a[:id] }).to eq [ {
      'id' => admin.id,
      'account_id' => admin.account.id,
      'entity_user_id' => admin.entity_user_id,
      'full_name' => 'Administrator',
      'name' => admin.name,
      'username' => 'admin',
      'is_admin' => true,
      'is_content_analyst' => false
    }, {
      'id' => profile.id,
      'account_id' => profile.account.id,
      'entity_user_id' => profile.entity_user_id,
      'full_name' => 'User One',
      'name' => profile.name,
      'username' => 'student',
      'is_admin' => false,
      'is_content_analyst' => false
    } ]
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
    expect(assigns[:user_search].items.first).to include(
      username: 'new',
      name: 'New User',
      full_name: 'Overriden!',
      is_admin: false,
      is_content_analyst: true)
  end

  it 'updates a user' do
    put :update, id: profile.id, user: {
      username: 'updated',
      full_name: 'Updated Name',
      content_analyst: true
    }

    expect(profile.reload.username).to eq 'updated'
    expect(profile.full_name).to eq 'Updated Name'
    expect(profile.is_admin?).to eq false
    expect(profile.is_content_analyst?).to eq true
  end
end

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let!(:admin) do
    FactoryBot.create :user_profile, :administrator, first_name: 'Ad', last_name: 'Min',
                                                     username: 'admin', full_name: 'Admin'
  end
  let!(:user) { FactoryBot.create :user_profile, username: 'student', full_name: 'User One' }

  before { sign_in! admin }

  context '#index' do
    let(:query)    { 'some query' }
    let(:order_by) { 'some_field some_direction' }
    let(:page)     { 42 }
    let(:per_page) { 21 }
    let(:users)    { [ admin, user ] }

    it 'passes query, order_by, page and per_page to User::SearchUsers and assigns the result' do
      expect(User::SearchUsers).to receive(:call).with(
        query: query, order_by: order_by, page: page.to_s, per_page: per_page.to_s
      ).and_return(OpenStruct.new(outputs: OpenStruct.new(items: users)))

      get admin_users_url,
          params: { query: query, order_by: order_by, page: page, per_page: per_page }

      expect(assigns[:user_search].items).to eq users
    end
  end

  it 'creates a new user' do
    post admin_users_url, params: {
      user: {
        username: 'new',
        password: 'password',
        first_name: 'New',
        last_name: 'User',
        full_name: 'Overriden!',
        customer_support: '1',
        content_analyst: true,
        researcher: true
      }
    }

    get admin_users_url, params: { query: 'new' }
    expect(assigns[:user_search].items.length).to eq 1
    user = assigns[:user_search].items.first
    expect(user.username).to eq 'new'
    expect(user.first_name).to eq 'New'
    expect(user.last_name).to eq 'User'
    expect(user.name).to eq 'Overriden!'
    expect(user.is_admin?).to eq false
    expect(user.is_customer_support?).to eq true
    expect(user.is_content_analyst?).to eq true
    expect(user.is_researcher?).to eq true
  end

  it 'updates a user' do
    put admin_user_url(user.id), params: {
      user: {
        username: 'updated',
        full_name: 'Updated Name',
        customer_support: '1',
        content_analyst: true,
        researcher: true
      }
    }

    user.reload

    expect(user.username).to eq 'updated'
    expect(user.name).to eq 'Updated Name'
    expect(user.is_admin?).to eq false
    expect(user.is_customer_support?).to eq true
    expect(user.is_content_analyst?).to eq true
    expect(user.is_researcher?).to eq true
  end
end

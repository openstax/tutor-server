require 'rails_helper'

RSpec.describe CustomerService::UsersController, type: :controller do
  let!(:customer_service) {
    profile = FactoryGirl.create :user_profile, :customer_service,
                                                username: 'cs',
                                                full_name: 'Customer Service'
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

  before { controller.sign_in(customer_service) }

  it 'searches users by username and full name' do
    get :index, query: 'RVI'
    expect(assigns[:user_search].items.length).to eq 1
    expect(assigns[:user_search].items).to eq [ customer_service ]

    get :index, query: 's'
    expect(assigns[:user_search].items.length).to eq 2
    expect(assigns[:user_search].items.sort_by { |a| a.id }).to eq [ customer_service, user ]
  end
end

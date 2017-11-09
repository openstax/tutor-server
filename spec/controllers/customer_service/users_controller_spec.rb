require 'rails_helper'

RSpec.describe CustomerService::UsersController, type: :controller do
  let!(:customer_service) { FactoryBot.create :user, :customer_service,
                                                      username: 'cs',
                                                      full_name: 'Customer Service' }
  let!(:user) { FactoryBot.create :user, username: 'student', full_name: 'User One' }

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

require 'rails_helper'

RSpec.describe CustomerService::UsersController, type: :controller do
  let!(:customer_service) do
    FactoryBot.create :user, :customer_service, first_name: 'Customer', last_name: 'Support',
                                                username: 'support', full_name: 'Customer Support'
  end
  let!(:user) { FactoryBot.create :user, username: 'student', full_name: 'User One' }

  before { controller.sign_in(customer_service) }

  context '#index' do
    let(:query)    { 'some query' }
    let(:order_by) { 'some_field some_direction' }
    let(:page)     { 42 }
    let(:per_page) { 21 }
    let(:users)    { [ customer_service, user ] }

    it 'passes query, order_by, page and per_page to User::SearchUsers and assigns the result' do
      expect(User::SearchUsers).to receive(:call).with(
        query: query, order_by: order_by, page: page.to_s, per_page: per_page.to_s
      ).and_return(OpenStruct.new(outputs: OpenStruct.new(items: users)))

      get :index, params: { query: query, order_by: order_by, page: page, per_page: per_page }

      expect(assigns[:user_search].items).to eq users
    end
  end
end

require 'rails_helper'

# Need truncation: true because transaction_retry only retries top-level transactions
RSpec.describe TransactionRetry, type: :lib, truncation: true do
  it 'retries ActiveRecord::PreparedStatementCacheExpired' do
    result = nil

    ActiveRecord::Base.transaction do
      if result.nil?
        result = 21

        raise ActiveRecord::PreparedStatementCacheExpired.new('test')
      else
        result = 42
      end
    end

    expect(result).to eq 42
  end
end

require 'rails_helper'

RSpec.describe GetSalesforceBookNames, type: :routine do
  let(:book_names) { ['Biology', 'College Physics (Algebra)'] }

  before { ActiveForce.cache_store.set('book_names', nil) }

  it 'queries the salesforce book model to get book names' do
    expect(OpenStax::Salesforce::Remote::Book).to(
      receive(:all).once.and_return(book_names.map { |name| OpenStruct.new(name: name) })
    )

    expect(described_class[]).to eq book_names
  end

  it 'returns cached results in subsequent calls' do
    expect(OpenStax::Salesforce::Remote::Book).to(
      receive(:all).once.and_return(book_names.map { |name| OpenStruct.new(name: name) })
    )

    expect(described_class[]).to eq book_names
    expect(described_class[]).to eq book_names
    expect(described_class[]).to eq book_names
  end

  it 'does not use the cached value if a forced cache miss is requested' do
    expect(OpenStax::Salesforce::Remote::Book).to(
      receive(:all).twice.and_return(book_names.map { |name| OpenStruct.new(name: name) })
    )

    expect(described_class[]).to eq book_names
    expect(described_class[true]).to eq book_names
    expect(described_class[]).to eq book_names
  end

  it 'does not blow up if Salesforce is not configured' do
    expect(OpenStax::Salesforce::Remote::Book).to receive(:all).once do
      raise IllegalState, 'The Salesforce username is missing'
    end

    expect(described_class[]).to be_nil
  end
end

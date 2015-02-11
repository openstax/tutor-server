require 'rails_helper'

RSpec.describe Book, :type => :model do
  subject { FactoryGirl.create :book }

  it { is_expected.to belong_to(:parent_book) }

  it { is_expected.to have_many(:child_books).dependent(:destroy) }

  it { is_expected.to have_many(:pages).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
end

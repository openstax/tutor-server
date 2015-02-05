require 'rails_helper'

RSpec.describe Interactive, :type => :model do
  it { is_expected.to have_many(:book_interactives).dependent(:destroy) }
end

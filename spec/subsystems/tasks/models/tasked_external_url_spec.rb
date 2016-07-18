require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExternalUrl, type: :model do
  it { is_expected.to validate_presence_of(:url) }
end

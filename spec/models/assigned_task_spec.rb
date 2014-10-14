require 'rails_helper'

RSpec.describe AssignedTask, :type => :model do
  it { is_expected.to belong_to(:assignee) }
  it { is_expected.to belong_to(:task).counter_cache(true) }
  it { is_expected.to belong_to(:user) }
end


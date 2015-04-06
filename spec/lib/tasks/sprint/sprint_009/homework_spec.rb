require 'rails_helper'
require 'tasks/sprint/sprint_009/homework'

RSpec.describe Sprint009::Homework, type: :request, :api => true, :version => :v1 do

  it "doesn't catch on fire" do
    Sprint009::Homework.call
  end

end

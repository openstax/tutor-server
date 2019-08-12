require 'rails_helper'

RSpec.describe Api::V1::ErrorRepresenter, type: :representer do
  let(:exception_error) do
    Hashie::Mash.new(
      is_fatal: true,
      code: "exception",
      message: "undefined local variable or method `name' for #<Tasks::GetPerformanceReport:0x007f5fff1a7f00>",
      data: "blah blah"
    )
  end

  it 'handles hash errors (errors are hashes)' do
    expect { described_class.new(exception_error).to_hash }.not_to raise_error
  end
end

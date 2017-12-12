require 'rails_helper'

RSpec.describe SecureRandomTokenGenerator, type: :lib do
  let(:length)          { 9 }
  let(:prefix)          { 'r' }
  let(:suffix)          { 'l' }
  let(:options)         { { length: length, prefix: prefix, suffix: suffix } }
  let(:token_generator) { described_class.new(mode, options) }

  it 'can list its handled modes' do
    expect(described_class.handled_modes).to be_a(Array)
    described_class.handled_modes.each { |mode| expect(mode).to be_a(Symbol) }
  end

  {
    hex: ->(length) { 2 * length },
    urlsafe_base64: ->(length) { 4 * length/3.0 },
    base64: ->(length) { 4 * length/3.0 },
    random_number: ->(length) { length },
    uuid: ->(length) { 36 }
  }.each do |mode, length_proc|
    context mode.to_s do
      let(:mode) { mode }

      it "can generate #{mode} tokens with the correct length, prefix and suffix" do
        result = token_generator.run

        if result.is_a?(String)
          expect(result).to start_with(prefix)
          expect(result).to end_with(suffix)
        end

        expect(result.to_s.chomp(suffix).reverse.chomp(prefix).size).to eq length_proc.call(length)
      end
    end
  end
end

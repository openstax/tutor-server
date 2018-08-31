require 'rails_helper'

RSpec.describe Tutor::Assets, type: :lib do
  PathStub = Struct.new(:exist?, :mtime, :read) do
    def expand_path
      'foo/bar/baz'
    end
  end

  it 'defaults to url when manifest is missing' do
    stub_const('Tutor::Assets::Manifest::SOURCE', PathStub.new(false))
    Tutor::Assets.read_manifest
    expect(Tutor::Assets[:foo, :bar]).to eq 'http://localhost:8000/dist/foo.bar'
  end

  it 'reads json from manifest' do
    stub_const(
      'Tutor::Assets::Manifest::SOURCE',
      PathStub.new(true, 1234, '{"foo.min.bar": "foo-732c56c32ff399b62.min.bar"}')
    )
    Tutor::Assets.read_manifest
    expect(Tutor::Assets[:foo, :bar]).to eq 'http://localhost:8000/dist/foo-732c56c32ff399b62.min.bar'
  end

  it 're-reads manifest when mtime changes' do
    stub = PathStub.new(true, 1234, '{"foo.min.bar": "foo-1.min.bar"}')
    stub_const('Tutor::Assets::Manifest::SOURCE', stub)
    Tutor::Assets.read_manifest
    expect(stub).to receive(:mtime).and_return(0, 1)
    expect(stub).to receive(:read).and_return('{"foo.min.bar": "foo-2.min.bar"}')
    expect(Tutor::Assets[:foo, :bar]).to eq 'http://localhost:8000/dist/foo-2.min.bar'
  end
end

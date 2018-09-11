require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tutor::Assets, vcr: VCR_OPTS do

  PathStub = Struct.new(:exist?, :mtime, :read) do
    def expand_path
      'foo/bar/baz'
    end
  end

  it 'defaults to url when manifest is missing' do
    stub_const('Tutor::Assets::Manifest::Local::SOURCE', PathStub.new(false))
    Tutor::Assets.read_manifest
    expect(Tutor::Assets[:foo, :bar]).to eq 'http://localhost:8000/dist/foo.bar'
  end

  it 'reads json from manifest' do
    stub_const(
      'Tutor::Assets::Manifest::Local::SOURCE',
      PathStub.new(true, 1234, '{"foo.min.bar": "foo-732c56c32ff399b62.min.bar"}')
    )
    Tutor::Assets.read_manifest
    expect(Tutor::Assets[:foo, :bar]).to eq 'http://localhost:8000/dist/foo-732c56c32ff399b62.min.bar'
  end

  it 're-reads manifest when mtime changes' do
    stub = PathStub.new(true, 1234, '{"foo.min.bar": "foo-1.min.bar"}')
    stub_const('Tutor::Assets::Manifest::Local::SOURCE', stub)
    Tutor::Assets.read_manifest
    expect(stub).to receive(:mtime).and_return(0, 1)
    expect(stub).to receive(:read).and_return('{"foo.min.bar": "foo-2.min.bar"}')
    expect(Tutor::Assets[:foo, :bar]).to eq 'http://localhost:8000/dist/foo-2.min.bar'
  end

  it 'reads remote url' do
    expect(Rails.application.secrets).to(
      receive(:assets_manifest_url).at_least(:once).and_return(
        'https://tutor-dev.openstax.org/assets/rev-manifest.json'
      )
    )
    Tutor::Assets.read_manifest
    expect(
      Tutor::Assets.instance_variable_get(:'@manifest')
    ).to be_kind_of Tutor::Assets::Manifest::Remote
    expect(Tutor::Assets::Scripts[:tutor]).to(
      eq 'http://localhost:8000/dist/tutor-991511e12f76aa9aa1ddcb7732c56c32ff399b62.min.js'
    )
  end
end

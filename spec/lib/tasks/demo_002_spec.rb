require 'rails_helper'
require 'vcr_helper'
require 'tasks/demo_001'
require 'tasks/demo_002'
require 'tasks/demo/content_configuration'

RSpec.describe Demo002, type: :request, version: :v1, speed: :slow, vcr: VCR_OPTS do

  context 'with the stable book version' do
    it "doesn't catch on fire" do
      # Demo002 depends on Demo001
      # For testing a lightweight imports is performed so it completes faster
      # The customized import files for the are located in the fixtures directory
      fixtures_directory = File.join(File.dirname(__FILE__),'../../fixtures/demo-imports')

      ContentConfiguration.with_config_directory(fixtures_directory) do
        expect(Demo001.call(print_logs: true).errors).to be_empty
        expect(Demo002.call(print_logs: true).errors).to be_empty
      end
    end
  end

end

require 'rails_helper'
require 'vcr_helper'
require 'tasks/demo/content'
require 'tasks/demo/tasks'
require 'tasks/demo/work'

RSpec.describe 'Demo', type: :request, version: :v1, speed: :slow, vcr: VCR_OPTS do

  context 'with the stable book version' do
    it "doesn't catch on fire" do
      # The demo rake task runs demo:content, demo:tasks and demo:work
      # For testing a lightweight imports is performed so it completes faster
      # The customized import files for the are located in the fixtures directory
      fixtures_directory = File.join(File.dirname(__FILE__),'../../fixtures/demo-imports')
      ContentConfiguration.with_config_directory(fixtures_directory) do
        expect(DemoContent.call(print_logs: false).errors).to be_empty
        expect(DemoTasks.call(print_logs: false).errors).to be_empty
        expect(DemoWork.call(print_logs: false).errors).to be_empty
      end
    end
  end

end

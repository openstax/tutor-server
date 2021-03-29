require 'rails_helper'

RSpec.describe 'cron:minute', type: :rake do
  include_context 'rake'

  it 'calls all configured rake tasks' do
    expect(Rake::Task['aws:update_cloudwatch_metrics']).to receive(:invoke)
    expect(Rake::Task['openstax:accounts:sync:accounts']).to receive(:invoke)
    expect(Rake::Task['delayed:heartbeat:delete_timed_out_workers']).to receive(:invoke)

    call
  end
end

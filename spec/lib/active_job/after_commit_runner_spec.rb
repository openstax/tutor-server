require 'rails_helper'

class TestJob < ActiveJob::Base
  cattr_reader :performed_count
  @@performed_count = 0

  def perform(count)
    @@performed_count += count
  end
end

RSpec.describe ActiveJob::AfterCommitRunner, type: :lib, truncation: true do
  before(:all)      { Delayed::Worker.delay_jobs = true      }
  after(:all)       { Delayed::Worker.delay_jobs = false     }

  let(:increment)   { 42                                     }
  let(:job)         { TestJob.perform_later(increment)       }
  let(:delayed_job) { Delayed::Job.find(job.provider_job_id) }
  let(:runner)      { described_class.new(job)               }

  context '#initialize' do
    it 'reserves the Delayed::Job associated with the given ActiveJob' do
      expect { runner }.to  change     { delayed_job.reload.locked_at }
                       .and change     { delayed_job.locked_by        }
                       .and not_change { TestJob.performed_count      }
    end
  end

  context '#run_after_commit' do
    context 'in a transaction' do
      it 'runs the given job when the transaction commits' do
        expect do
          Delayed::Job.transaction do
            expect(Delayed::Job.connection.open_transactions).to eq(1)
            expect { runner.run_after_commit }.to  change     { delayed_job.reload.locked_at }
                                              .and change     { delayed_job.locked_by        }
                                              .and not_change { TestJob.performed_count      }
          end
        end.to change { TestJob.performed_count }.by(increment)

        expect{ delayed_job.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not do anything if the transaction rolls back' do
        expect do
          Delayed::Job.transaction do
            expect(Delayed::Job.connection.open_transactions).to eq(1)
            expect { runner.run_after_commit }.to  change     { delayed_job.reload.locked_at }
                                              .and change     { delayed_job.locked_by        }
                                              .and not_change { TestJob.performed_count      }

            raise ActiveRecord::Rollback
          end
        end.to  not_change { delayed_job.reload.locked_at }
           .and not_change { delayed_job.locked_by        }
           .and not_change { TestJob.performed_count      }
      end
    end

    context 'not in a transaction' do
      before { expect(Delayed::Job.connection.open_transactions).to eq(0) }

      it 'runs the given job immediately' do
        expect { runner.run_after_commit }.to change { TestJob.performed_count }.by(increment)

        expect{ delayed_job.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

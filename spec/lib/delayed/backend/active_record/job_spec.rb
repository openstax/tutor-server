require 'rails_helper'

module Delayed::Backend::ActiveRecord
  RSpec.describe Job, type: :model do
    context '#ready_to_run' do
      before(:all) do
        @worker_name = 'test_worker'
        another_worker_name = 'another_worker'
        @default_max_run_time = 5.minutes
        current_time = Time.current

        DatabaseCleaner.start

        @ready_job = FactoryGirl.create :delayed_job, run_at: current_time
        @future_job = FactoryGirl.create :delayed_job, run_at: current_time.tomorrow
        @locked_same_worker_job = FactoryGirl.create :delayed_job,
                                                     run_at: current_time,
                                                     locked_at: current_time,
                                                     locked_by: @worker_name
        @locked_different_worker_job = FactoryGirl.create :delayed_job,
                                                          run_at: current_time,
                                                          locked_at: current_time,
                                                          locked_by: another_worker_name
        @non_expired_locked_job = FactoryGirl.create :delayed_job,
                                                     run_at: current_time,
                                                     locked_at: current_time - 4.minutes,
                                                     locked_by: another_worker_name
        @expired_locked_job = FactoryGirl.create :delayed_job,
                                                 run_at: current_time,
                                                 locked_at: current_time - 5.minutes,
                                                 locked_by: another_worker_name
        @non_expired_high_pri_job = FactoryGirl.create :delayed_job,
                                                       run_at: current_time,
                                                       queue: 'high_priority',
                                                       locked_at: current_time - 10.seconds,
                                                       locked_by: another_worker_name
        @expired_high_pri_job = FactoryGirl.create :delayed_job,
                                                   run_at: current_time,
                                                   queue: 'high_priority',
                                                   locked_at: current_time - 1.minute,
                                                   locked_by: another_worker_name
        @non_expired_low_pri_job = FactoryGirl.create :delayed_job,
                                                      run_at: current_time,
                                                      queue: 'low_priority',
                                                      locked_at: current_time - 25.minutes,
                                                      locked_by: another_worker_name
        @expired_low_pri_job = FactoryGirl.create :delayed_job,
                                                  run_at: current_time,
                                                  queue: 'low_priority',
                                                  locked_at: current_time - 30.minutes,
                                                  locked_by: another_worker_name
        @non_expired_long_running_job = FactoryGirl.create :delayed_job,
                                                           run_at: current_time,
                                                           queue: 'long_running',
                                                           locked_at: current_time - 3.hours,
                                                           locked_by: another_worker_name
        @expired_long_running_job = FactoryGirl.create :delayed_job,
                                                       run_at: current_time,
                                                       queue: 'long_running',
                                                       locked_at: current_time - 4.hours,
                                                       locked_by: another_worker_name
      end

      after(:all)  { DatabaseCleaner.clean }

      it 'returns jobs with run_at in the past and locked by the same worker or expired lock' do
        expect(described_class.ready_to_run(@worker_name, @default_max_run_time)).to match_array [
          @ready_job, @locked_same_worker_job, @expired_locked_job,
          @expired_high_pri_job, @expired_low_pri_job, @expired_long_running_job
        ]
      end
    end
  end
end

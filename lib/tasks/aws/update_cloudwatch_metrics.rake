namespace :aws do
  task update_cloudwatch_metrics: :environment do
    dj = Delayed::Job.arel_table
    current_time = Time.current
    max_run_time = Delayed::Worker.max_run_time
    environment_name = Rails.application.secrets.environment_name
    min_effective_run_at_by_queue = {}
    Delayed::Job.where(locked_at: nil).or(
      Delayed::Job.where(dj[:locked_at].lt current_time - max_run_time)
    ).where(dj[:run_at].lteq current_time).where(failed_at: nil).group(:queue).pluck(
      <<~SELECT
        "delayed_jobs"."queue", MIN(
          GREATEST(
            "delayed_jobs"."run_at",
            "delayed_jobs"."locked_at" + INTERVAL '#{max_run_time} seconds'
          )
        ) AS "min_effective_run_at"
      SELECT
    ).each do |queue, min_effective_run_at|
      min_effective_run_at_by_queue[queue.sub("tutor_#{Rails.env}_", '')] = min_effective_run_at
    end

    require 'aws-sdk-cloudwatch'

    client = Aws::CloudWatch::Client.new
    default_dimensions = [
      { name: 'Application', value: 'tutor' }, { name: 'Environment', value: environment_name }
    ]

    ([ '' ] + Delayed::Worker.queue_attributes.keys.map(&:to_s)).each_slice(20) do |queues|
      client.put_metric_data(
        namespace: 'DelayedJob',
        metric_data: queues.map do |queue|
          dimensions = default_dimensions
          dimensions += [ { name: 'Queue', value: queue } ] unless queue.blank?
          min_effective_run_at = queue.blank? ? min_effective_run_at_by_queue.values.compact.min :
                                                min_effective_run_at_by_queue[queue]

          {
            metric_name: 'MaxWait',
            dimensions: dimensions,
            timestamp: current_time,
            value: min_effective_run_at.nil? ? 0 : current_time - min_effective_run_at,
            unit: 'Seconds'
          }
        end
      )
    end
  end
end

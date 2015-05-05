module Queues
  module Jobs
    class ExportPerformanceBookJob < ActiveJob::Base
      queue_as :default

      def perform(role:, course:)
        File.open('/tmp/sup.xlsx', 'w') do |f|
          f.write('something')
        end
        Tasks::Models::PerformanceBookExport.create!(filename: 'sup')
      end
    end
  end
end

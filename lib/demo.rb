module Api
  module V1
    module Demo
      module Course
        module Period
        end
      end

      module Task
      end

      module Work
      end
    end
  end
end

module Demo
  DEFAULT_CONFIG = 'review'
  CONFIG_BASE_DIR = File.join Rails.root, 'config', 'demo'
end

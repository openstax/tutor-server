module Settings
  module ResponseValidation

    class << self

      def is_enabled
        Settings::Db.response_validation_enabled
      end

      def is_enabled=(value)
        Settings::Db.response_validation_enabled = value
      end

      def is_ui_enabled
        Settings::Db.response_validation_ui_enabled
      end

      def is_ui_enabled=(value)
        Settings::Db.response_validation_ui_enabled = value
      end

    end

  end
end

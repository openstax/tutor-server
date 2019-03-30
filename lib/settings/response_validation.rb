module Settings
  module ResponseValidation

    class << self

      def is_enabled
        Settings::Db.store.response_validation_enabled
      end

      def is_enabled=(value)
        Settings::Db.store.response_validation_enabled = value
        Settings::Db.store.object('response_validation_enabled').expire_cache
      end

      def is_ui_enabled
        Settings::Db.store.response_validation_ui_enabled
      end

      def is_ui_enabled=(value)
        Settings::Db.store.response_validation_ui_enabled = value
        Settings::Db.store.object('response_validation_ui_enabled').expire_cache
      end

    end

  end
end

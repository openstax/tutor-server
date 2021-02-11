module User
  module Models
    class Suggestion < ApplicationRecord
      validates :content, presence: true
      validates :topic, presence: true

      enum topic: [:subject]

      before_validation :limit_subject_length

      def limit_subject_length
        return unless content.present? && topic == 'subject'
        self.content = content.slice(0, 49)
      end
    end
  end
end

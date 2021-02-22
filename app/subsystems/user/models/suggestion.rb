module User
  module Models
    class Suggestion < ApplicationRecord
      belongs_to :profile, subsystem: :user

      validates :content, presence: true
      validates :topic, presence: true
      validates :profile, presence: true

      enum topic: [:subject]

      before_validation :limit_subject_length

      def limit_subject_length
        return unless content.present? && topic == 'subject'
        self.content = content.slice(0, 49)
      end
    end
  end
end

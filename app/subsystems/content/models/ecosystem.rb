module Content
  module Models
    class Ecosystem < ApplicationRecord

      acts_as_paranoid without_default_scope: true

      wrapped_by ::Content::Strategies::Direct::Ecosystem

      auto_uuid :tutor_uuid

      has_many :course_ecosystems, subsystem: :course_content
      has_many :courses, through: :course_ecosystems, subsystem: :course_profile

      has_many :task_plans, subsystem: :tasks, dependent: :destroy
      has_many :tasks, subsystem: :tasks, dependent: :destroy

      has_many :books, inverse_of: :ecosystem
      has_many :chapters, through: :books
      has_many :pages, through: :chapters
      has_many :exercises, through: :pages

      has_many :pools, inverse_of: :ecosystem

      has_many :tags, inverse_of: :ecosystem

      has_many :to_maps, class_name: '::Content::Models::Map',
                         foreign_key: :content_from_ecosystem_id,
                         inverse_of: :from_ecosystem
      has_many :from_maps, class_name: '::Content::Models::Map',
                           foreign_key: :content_to_ecosystem_id,
                           inverse_of: :to_ecosystem

      default_scope -> { order(created_at: :desc) }

      before_validation :set_title, on: :create, unless: :title

      validates :title, presence: true

      def deletable?
        course_ecosystems.empty?
      end

      def manifest_hash
        {
          title: title,
          books: books.map(&:manifest_hash)
        }
      end

      def set_title
        self.title = books.empty? ?
          'Empty Ecosystem' : "#{books.map(&:title).join('; ')} (#{books.map(&:cnx_id).join('; ')})"
      end

    end
  end
end

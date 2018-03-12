class Catalog::Models::Offering < ApplicationRecord

  DELETABLE_SQL = <<-DEL_SQL.strip_heredoc
    NOT EXISTS (
      SELECT * FROM "course_profile_courses"
      WHERE "course_profile_courses"."catalog_offering_id" = "catalog_offerings"."id"
    ) AS "deletable"
  DEL_SQL

  sortable_class on: :number

  belongs_to :ecosystem, subsystem: :content

  has_many :courses, subsystem: :course_profile

  validates :salesforce_book_name,  presence: true
  validates :webview_url, presence: true
  validates :title, presence: true
  validates :description, presence: true
  validates :ecosystem, presence: true

  before_destroy :no_courses

  wrapped_by ::Catalog::Strategies::Direct::Offering

  scope :preload_deletable, -> do
    select([ arel_table[Arel.star], DELETABLE_SQL ] )
  end

  def deletable?
    respond_to?(:deletable) ? deletable : courses.empty?
  end

  protected

  def no_courses
    return if courses.empty?

    errors.add :base, 'cannot be deleted because there are courses that use it'
    false
  end

end

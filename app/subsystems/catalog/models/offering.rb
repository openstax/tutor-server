class Catalog::Models::Offering < Tutor::SubSystems::BaseModel

  belongs_to :ecosystem, subsystem: :content

  validates :identifier,  presence: true
  validates :webview_url, presence: true
  validates :description, presence: true

  def is_tutor?
    flags.has_key?('is_tutor')
  end

  def is_concept_coach?
    flags.has_key?('is_concept_coach')
  end


end

class Catalog::Models::Offering < Tutor::SubSystems::BaseModel

  belongs_to :ecosystem, subsystem: :content

  validates :identifier,  presence: true, uniqueness: true
  validates :webview_url, presence: true
  validates :description, presence: true
  validates :ecosystem, presence: true

  wrapped_by ::Catalog::Strategies::Direct::Offering

end

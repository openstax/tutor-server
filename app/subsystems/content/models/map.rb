class Content::Models::Map < Tutor::SubSystems::BaseModel
  belongs_to :from_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :to_maps
  belongs_to :to_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :from_maps

  validates :from_ecosystem, :to_ecosystem, presence: true
  validates :to_ecosystem, uniqueness: { scope: :content_from_ecosystem_id }
end

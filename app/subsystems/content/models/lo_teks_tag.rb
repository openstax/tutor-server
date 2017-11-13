class Content::Models::LoTeksTag < IndestructibleRecord
  belongs_to :lo, class_name: 'Tag', foreign_key: :lo_id
  belongs_to :teks, class_name: 'Tag', foreign_key: :teks_id

  validates :lo, presence: true
  validates :teks, presence: true, uniqueness: { scope: :lo_id }
end

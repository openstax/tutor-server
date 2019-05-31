class Content::Models::LoTeksTag < IndestructibleRecord
  belongs_to :lo, class_name: 'Tag', foreign_key: :lo_id
  belongs_to :teks, class_name: 'Tag', foreign_key: :teks_id

  validates :teks, uniqueness: { scope: :lo_id }
end

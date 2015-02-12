class KlassAssistant < ActiveRecord::Base
  belongs_to :klass
  belongs_to :assistant

  validates :klass, presence: true
  validates :assistant, presence: true, uniqueness: { scope: :klass_id }
end

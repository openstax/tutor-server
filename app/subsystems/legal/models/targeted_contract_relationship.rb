class Legal::Models::TargetedContractRelationship < Tutor::SubSystems::BaseModel

  validates :child_gid, presence: true,
                        uniqueness: { scope: :parent_gid }
  validates :parent_gid, presence: true

  def self.all_parents_of(child)
    immediate_parents = where(child: child).all.collect(&:parent)
    [
      immediate_parents +
      immediate_parents.collect do |parent|
        parent.nil? ? nil : all_parents_of(parent)
      end
    ].flatten.compact.uniq
  end

end

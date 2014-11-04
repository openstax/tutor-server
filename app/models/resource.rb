class Resource < ActiveRecord::Base
  CONTAINERS = [:readings, :interactives]

  CONTAINERS.each do |container|
    has_many container
  end

  validates :url, uniqueness: true

  def destroy
    # Resources are shared between many objects, so only delete
    # if none of those exist.
    return if CONTAINERS.any?{|container| self.send(container).any?}
    super
  end

  def delete
    destroy
  end
end

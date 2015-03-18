# Accepts an array of page_ids
# Returns outputs :pages as an array of hashes with :id, :url, :content keys

class Content::Api::GetPagesAttributes

  EXPORTED_COLUMNS = [:id, :url, :number, :title]

  lev_routine

  protected

  def exec(page_ids:)
    # the map is crazy looking but turns an array into hash with EXPORTED_COLUMNS for keys
    outputs[:pages] = Content::Page.where(id: page_ids)
                      .pluck(*EXPORTED_COLUMNS)
                      .map{|row| Hash[*EXPORTED_COLUMNS.zip(row).flatten] }
  end

end

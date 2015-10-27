class TwoDMatrixHelper
  def self.find_cell(row:, column:)
    "#{([''] + ('A'..'Z').to_a)[column / 26]}#{('A'..'Z').to_a[column % 26]}#{row}"
  end
end

require 'rails_helper'

RSpec.describe TwoDMatrixHelper do
  describe '.find_cell' do
    it 'finds simple cells' do
      cell_reference = described_class.find_cell(row: 5, column: 0)
      expect(cell_reference).to eq('A5')

      cell_reference = described_class.find_cell(row: 99, column: 2)
      expect(cell_reference).to eq('C99')

      cell_reference = described_class.find_cell(row: 137, column: 25)
      expect(cell_reference).to eq('Z137')
    end

    it 'finds double-letter cells' do
      cell_reference = described_class.find_cell(row: 5, column: 26)
      expect(cell_reference).to eq('AA5')

      cell_reference = described_class.find_cell(row: 69, column: 27)
      expect(cell_reference).to eq('AB69')

      cell_reference = described_class.find_cell(row: 420, column: 57)
      expect(cell_reference).to eq('BF420')
    end

    it 'finds insane cells'
  end
end

require 'rails_helper'

RSpec.describe XlsxUtils, type: :lib do

  let(:dummy) { Class.new{ include XlsxUtils }.new }

  describe '#cell_ref' do
    it 'finds simple cells' do
      expect(dummy.cell_ref(row: 5, column: 0)).to eq('A5')
      expect(dummy.cell_ref(row: 99, column: 2)).to eq('C99')
      expect(dummy.cell_ref(row: 137, column: 25)).to eq('Z137')
    end

    it 'finds double-letter cells' do
      expect(dummy.cell_ref(row: 5, column: 26)).to eq('AA5')
      expect(dummy.cell_ref(row: 69, column: 27)).to eq('AB69')
      expect(dummy.cell_ref(row: 420, column: 57)).to eq('BF420')
    end
  end

  describe '#disjoin_range' do
    it 'works for scalar vals' do
      expect(dummy.disjoint_range(cols: "B", rows: "2")).to eq "B2"
    end

    it 'uses empty default' do
      expect(dummy.disjoint_range(cols: [], rows: "2")).to eq "NA()"
      expect(dummy.disjoint_range(cols: nil, rows: "2")).to eq "NA()"
      expect(dummy.disjoint_range(cols: "B", rows: [])).to eq "NA()"
      expect(dummy.disjoint_range(cols: "B", rows: nil)).to eq "NA()"
    end

    it 'works for scalar row' do
      expect(dummy.disjoint_range(cols: ["B","D"], rows: "2")).to eq "B2,D2"
    end

    it 'works for scalar col' do
      expect(dummy.disjoint_range(cols: "B", rows: ["2","4"])).to eq "B2,B4"
    end
  end

end

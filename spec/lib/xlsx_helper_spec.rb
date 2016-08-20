require 'rails_helper'

RSpec.describe XlsxHelper, type: :lib do

  describe '#sanitized_worksheet_name' do
    let(:helper) { described_class.new }

    it 'objects if no name provided' do
      expect{helper.sanitized_worksheet_name(name: nil)}.to raise_error(IllegalArgument)
    end

    it 'returns short names verbatim' do
      expect(helper.sanitized_worksheet_name(name: "Short name")).to eq "Short name"
    end

    it 'returns short names with suffixes with no truncation' do
      expect(helper.sanitized_worksheet_name(name: "Short name", suffix:"WOW")).to eq "Short nameWOW"
    end

    it 'replaces bad chars' do
      expect(helper.sanitized_worksheet_name(name: 'T:][\\/', suffix: '*?b:b')).to eq 'T-------b-b'
    end

    it 'leaves max length names alone' do
      expect(helper.sanitized_worksheet_name(name: '1234567890123456789012345678901')).to eq '1234567890123456789012345678901'
    end

    it 'truncates & numbers overlong names and resulting length is good' do
      expect(helper.sanitized_worksheet_name(name: '12345678901234567890123456789012')).to eq '1234567890123456789012345678-01'
    end

    it 'increments numbers for truncated names' do
      expect(helper.sanitized_worksheet_name(name: '12345678901234567890123456789012')).to eq '1234567890123456789012345678-01'
      expect(helper.sanitized_worksheet_name(name: "Short name")).to eq "Short name"
      expect(helper.sanitized_worksheet_name(name: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')).to eq 'aaaaaaaaaaaaaaaaaaaaaaaaaaaa-02'
    end

    it 'maintains full length suffixes when truncating' do
      expect(helper.sanitized_worksheet_name(name: '12345678901234567890123456789012', suffix: 'howdy')).to eq '12345678901234567890123-01howdy'
    end

    it 'objects if suffix too long' do
      expect{helper.sanitized_worksheet_name(name: '12345', suffix: '1234567890123456789012345678')}.to raise_error(IllegalArgument)
    end

    it 'does not object if suffix is max length' do
      expect{helper.sanitized_worksheet_name(name: '12345', suffix: '123456789012345678901234567')}.not_to raise_error
    end
  end

  describe '#cell_ref' do
    it 'finds simple cells' do
      expect(described_class.cell_ref(row: 5, column: 0)).to eq('A5')
      expect(described_class.cell_ref(row: 99, column: 2)).to eq('C99')
      expect(described_class.cell_ref(row: 137, column: 25)).to eq('Z137')
    end

    it 'finds double-letter cells' do
      expect(described_class.cell_ref(row: 5, column: 26)).to eq('AA5')
      expect(described_class.cell_ref(row: 69, column: 27)).to eq('AB69')
      expect(described_class.cell_ref(row: 420, column: 57)).to eq('BF420')
    end
  end

  describe '#disjoin_range' do
    it 'works for scalar vals' do
      expect(described_class.disjoint_range(cols: "B", rows: "2")).to eq "B2"
    end

    it 'uses empty default' do
      expect(described_class.disjoint_range(cols: [], rows: "2")).to eq "NA()"
      expect(described_class.disjoint_range(cols: nil, rows: "2")).to eq "NA()"
      expect(described_class.disjoint_range(cols: "B", rows: [])).to eq "NA()"
      expect(described_class.disjoint_range(cols: "B", rows: nil)).to eq "NA()"
    end

    it 'works for scalar row' do
      expect(described_class.disjoint_range(cols: ["B","D"], rows: "2")).to eq "B2,D2"
    end

    it 'works for scalar col' do
      expect(described_class.disjoint_range(cols: "B", rows: ["2","4"])).to eq "B2,B4"
    end
  end

end

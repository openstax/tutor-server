require 'rails_helper'

RSpec.describe FilenameSanitizer, type: :lib do
  let(:filenames) { [
    'my.file',
    'my c00l.file$',
    '_oh look\/another file_.exe',
    '/surely [a]* file.name?/',
    'Screen Shot 2016-05-20 at 9.00.00 AM.png',
    'Screenshot at 2016-05-20 09:00:00.png'
  ] }

  let(:sanitized_filenames) { [
    'my.file',
    'my_c00l.file',
    'oh_look_another_file_.exe',
    'surely_a_file.name',
    'Screen_Shot_2016-05-20_at_9.00.00_AM.png',
    'Screenshot_at_2016-05-20_09_00_00.png'
  ] }

  it 'sanitizes filenames' do
    filenames.each_with_index do |filename, index|
      expect(FilenameSanitizer.sanitize(filename)).to eq sanitized_filenames[index]
    end
  end
end

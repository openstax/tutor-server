require 'rails_helper'

RSpec.describe Content::Models::Page, type: :model do

  subject { FactoryGirl.create :content_page }

  it { is_expected.to belong_to(:chapter) }
  it { is_expected.to validate_presence_of(:title) }

  let!(:snap_lab_note) {
    <<-EOS.strip_heredoc
      <div data-type="note" data-has-label="true" id="fs-id1164355841632" class="note ost-assignable ost-reading-discard ost-assessed-feature snap-lab students-group safety-warning ost-tag-lo-k12phys-ch01-s02-lo02" data-label="Snap Lab">
        <div data-type="title" class="title">Using Models and the Scientific Processes</div>
          <p id="fs-id1167066861558">Be sure to secure loose items before opening the window or door.</p>
      </div>
    EOS
  }

  let!(:snap_lab_page) {
    FactoryGirl.create :content_page, content: <<-EOS.strip_heredoc
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">
      <html>
        <body>#{snap_lab_note}</body>
      </html>
    EOS
  }

  it 'returns snap labs' do
    snap_labs = snap_lab_page.snap_labs
    fragments = snap_labs.first[:fragments]
    expect(snap_labs).to eq([
      { id: "#{snap_lab_page.id}:fs-id1164355841632",
        title: 'Using Models and the Scientific Processes',
        fragments: fragments }
    ])
    expect(fragments.collect(&:class)).to eq([
      OpenStax::Cnx::V1::Fragment::Reading,
      OpenStax::Cnx::V1::Fragment::Exercise
    ])
  end

end

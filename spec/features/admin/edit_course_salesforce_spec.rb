require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Admin changing course Salesforce settings' do
  background do
    @course = FactoryGirl.create :course_profile_course
    @period_1 = FactoryGirl.create :course_membership_period, course: @course

    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)
  end

  scenario 'set excluded from salesforce' do
    go_to_salesforce_tab
    expect(page).to have_unchecked_field('course_is_excluded_from_salesforce')
    find(:css, '#course_is_excluded_from_salesforce').set(true)
    click_button 'exclusion_save'
    expect(@course.reload.is_excluded_from_salesforce).to eq true
    go_to_salesforce_tab
    expect(page).to have_checked_field('course_is_excluded_from_salesforce')
  end

  scenario 'setting blank SF record on periods' do
    go_to_salesforce_tab
    click_button 'Change'
    expect(current_path).to eq(edit_admin_course_path(@course))
    expect(page).to have_content('Salesforce record changed.')
  end

  context "when adding a new course SF record" do
    scenario 'leaving ID blank gives an error message' do
      go_to_salesforce_tab
      click_button 'Add'
      expect(current_path).to eq(edit_admin_course_path(@course))
      expect(page).to have_content('Salesforce can\'t be blank')
    end

    scenario 'a bad SF ID gives an error message' do
      go_to_salesforce_tab
      allow_any_instance_of(Admin::CoursesAddSalesforce).to(
        receive(:get_salesforce_object_for_id) { nil }
      )
      fill_in 'add_salesforce_salesforce_id', with: 'foo'
      click_button 'Add'
      expect(page).to have_content('does_not_exist')
    end

    scenario 'a valid, unused SF ID works' do
      existing_sf_object = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary, id: 'orig')
      FactoryGirl.create(:salesforce_attached_record, tutor_object: @course,
                                                      salesforce_object: existing_sf_object)
      go_to_salesforce_tab
      expect(page).to have_content('orig')

      new_sf_object = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary, id: 'new')
      fill_in 'add_salesforce_salesforce_id', with: 'new'
      click_button 'Add'
      expect(page).to have_content('orig')
      expect(page).to have_content('new')
    end

    scenario 'a valid, used SF ID gives an error' do
      existing_sf_object = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary,
                                          id: 'orig')
      FactoryGirl.create(:salesforce_attached_record, tutor_object: @course,
                                                      salesforce_object: existing_sf_object)
      go_to_salesforce_tab

      fill_in 'add_salesforce_salesforce_id', with: 'orig'
      click_button 'Add'
      expect(page).to have_content('orig')
      expect(page).to have_content('object_already_attached')
    end
  end

  context "when removing a course SF record" do
    before(:each) do
      sf_object = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary, id: 'orig')
      FactoryGirl.create(:salesforce_attached_record, tutor_object: @course,
                                                      salesforce_object: sf_object)
      FactoryGirl.create(:salesforce_attached_record, tutor_object: @period_1,
                                                      salesforce_object: sf_object)

      go_to_salesforce_tab

      expect(page).to have_content(/orig.*orig/) # maybe not the best test, but meh...
    end

    it "removes the same record from the relevant periods" do
      expect {
        click_button 'Remove'
      }.to change{Salesforce::Models::AttachedRecord.without_deleted.count}.by(-2)
      expect(page).not_to have_content(/orig.*orig/) # should just be one 'orig' now
    end

    it "can be restored" do
      click_button 'Remove'
      expect(page).to have_content(/orig/)
      expect{
        click_button 'Restore'
      }.to change{Salesforce::Models::AttachedRecord.without_deleted.count}.by(1)
    end
  end

  context "when there are two SF objects on a course with different periods on each" do
    before(:each) do
      period_2 = FactoryGirl.create :course_membership_period, course: @course
      sf_object_a = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary, id: 'sfoa')
      sf_object_b = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary, id: 'sfob')

      FactoryGirl.create(:salesforce_attached_record, tutor_object: @course,
                                                      salesforce_object: sf_object_a)
      FactoryGirl.create(:salesforce_attached_record, tutor_object: @period_1,
                                                      salesforce_object: sf_object_a)

      FactoryGirl.create(:salesforce_attached_record, tutor_object: @course,
                                                      salesforce_object: sf_object_b)
      FactoryGirl.create(:salesforce_attached_record, tutor_object: period_2,
                                                      salesforce_object: sf_object_b)
    end

    it "defaults the period SF dropdowns correctly" do
      go_to_salesforce_tab
      expect(page.body).to match(/1st.*selected="selected" value="sfoa".*2nd.*selected="selected" value="sfob"/m)
    end

    it "lets you change a period from one SF object to the other" do
      go_to_salesforce_tab
      expect(Salesforce::Models::AttachedRecord.where(salesforce_id: 'sfob').count).to eq 2
      select "sfob", from: "period_0_sf_select"
      page.all("input[type='submit'][value='Change']")[0].click
      expect(Salesforce::Models::AttachedRecord.where(salesforce_id: 'sfob').count).to eq 3
    end
  end

  def go_to_salesforce_tab
    visit edit_admin_course_path(@course)
    find("a[href='#salesforce']").click
    expect(page).to have_content('Salesforce Records')
  end

  def fake_sf_object(klass:, id:, save_outcome: true)
    klass.new(id: id).tap do |fake|
      allow(fake).to receive(:save) { save_outcome }   # stub save
      allow(klass).to receive(:find).with(id) { fake } # let lookup work
    end
  end


end

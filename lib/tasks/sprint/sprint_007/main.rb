module Sprint007
  class Main

    include WebMock::API

    lev_routine

    uses_routine OpenStax::Accounts::Dev::CreateAccount, 
                 as: :create_account,
                 translations: { outputs: {type: :verbatim} }

    protected

    def exec(username_or_user:)

      if username_or_user.is_a? String
        run(:create_account, username: username_or_user)
        legacy_user = UserMapper.account_to_user(outputs[:account])
      else
        legacy_user = username_or_user
      end

      #
      # BEGIN STUBBING CONTENT
      #
      # Would be great to import a book from CNX, but unfortunately we don't have good
      # content there yet.
      #

      book_hash = {
        id: "fake-cp-book-id",
        title: "College Physics",
        tree: {
          id: "fake-cp-tree-id",
          title: 'Chapter 1',
          contents: [
            {
              id: "subcol",
              title: 'Other chapter 1',
              contents: [
                {
                  id: "fake-cp-page1-id",
                  title: "Physical Quantities and Units"
                },
                {
                  id: "fake-cp-page2-id",
                  title: "Accuracy, Precision, and Significant Figures"
                },
              ]
            }
          ]
        }
      }
      
      stub_request(:get, "http://archive.cnx.org/contents/fake-cp-book-id").
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => book_hash.to_json, :headers => {})

      fixture_file = 'spec/fixtures/m50577/index.cnxml.html'
      page_content = open(fixture_file) { |f| f.read }

      stub_request(:get, "http://archive.cnx.org/contents/fake-cp-page1-id").
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :headers => {}, :body => {
          title: 'Dummy',
          id: 'page1',
          version: '1.0',
          content: page_content
        }.to_json )
        
      stub_request(:get, "http://archive.cnx.org/contents/fake-cp-page2-id").
        with(:headers => {'Accept'=>'text/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :headers => {}, :body => {
          title: 'Dummy',
          id: 'page2',
          version: '1.0',
          content: page_content
        }.to_json )

      #
      # END STUBBING CONTENT
      #

      book = Domain::ImportBook.call(cnx_id: 'fake-cp-book-id').outputs.book
      course = Domain::CreateCourse.call.outputs.course
      Domain::AddBookToCourse.call(book: book, course: course)
      user = LegacyUser::FindOrCreateUserForLegacyUser.call(legacy_user).outputs.user
      Domain::AddUserAsCourseTeacher.call(course: course, user: user)

      puts <<-TOKEN
        Added user #{legacy_user.account.username} as a teacher of course #{course.id}.
        There are readings available at /api/courses/#{course.id}/readings.
      TOKEN
    end

  end
end
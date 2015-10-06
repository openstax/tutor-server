namespace :openstax do
  namespace :biglearn do
    desc 'Gets CLUe updates from Biglearn and stores them in the local cache'
    task update_clues: :environment do |tt, args|
      UpdateClues.call
    end
  end
end

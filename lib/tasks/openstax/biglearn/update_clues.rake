namespace :openstax do
  namespace :biglearn do
    desc 'Gets all CLUes from Biglearn and stores them in the local cache'
    task update_all_clues: :environment do |tt, args|
      UpdateClues[type: :all]
    end

    desc 'Gets recently worked CLUes from Biglearn and stores them in the local cache'
    task update_recent_clues: :environment do |tt, args|
      UpdateClues[type: :recent]
    end
  end
end

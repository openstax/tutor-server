namespace :openstax do
  namespace :biglearn do
    desc 'Gets period CLUe updates from Biglearn and stores them in the local cache'
    task update_period_clues: :environment do |tt, args|
      UpdatePeriodClues.call
    end
  end
end

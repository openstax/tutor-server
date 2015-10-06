namespace :openstax do
  namespace :biglearn do
    namespace :clues do
      namespace :update do
        desc 'Gets all CLUes from Biglearn and stores them in the local cache'
        task all: :environment do |tt, args|
          UpdateClues[type: :all]
        end

        desc 'Gets recently worked CLUes from Biglearn and stores them in the local cache'
        task recent: :environment do |tt, args|
          UpdateClues[type: :recent]
        end
      end
    end
  end
end

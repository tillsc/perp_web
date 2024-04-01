namespace :cleanup do
  PROGRESS_BAR_FORMAT = '%a <%B> %p%% %t'
  namespace :encoding do

    desc "Tries to fix encoding problems in rower names"
    task rowers: :environment do
      scope = Rower.with_encoding_problems
      progressbar = ProgressBar.create(total: scope.count, format: PROGRESS_BAR_FORMAT)
      scope.find_each do |rower|
        Rower::TYPICAL_ENCODING_PROBLEMS.each do |pattern, replacement|
          rower.last_name.gsub!(pattern, replacement)
          rower.first_name.gsub!(pattern, replacement)
        end
        rower.save!
        progressbar.increment
      end
    end
  end

  namespace :duplicate do

    desc "Removes all duplicate rowers having no external id, replacing them in their start lists and results"
    task rowers: :environment do
      scope = Rower.
        where(external_id: nil).
        where(<<-QUERY)
EXISTS (
SELECT 1 FROM ruderer r2 WHERE 
  r2.ID <> ruderer.ID AND 
  r2.VName = ruderer.VName AND r2.NName = ruderer.NName AND 
  (r2.JahrG = ruderer.JahrG OR (IFNULL(ruderer.JahrG, '') = '' AND ruderer.Verein_ID = r2.Verein_ID))
)
QUERY

      progressbar = ProgressBar.create(total: scope.count, format: PROGRESS_BAR_FORMAT)
      scope.find_each do |rower|
        if new_rower = rower.duplicates.first
          if rower.participants.any?
            Participant::ALL_ROWER_IDX.each do |i|
              Participant.connection.execute("UPDATE meldungen SET ruderer#{i}_ID=#{new_rower.id} WHERE ruderer#{i}_ID=#{rower.id}")
            end
          end
          rower.destroy!
        end
        progressbar.increment
      end

    end

  end
end
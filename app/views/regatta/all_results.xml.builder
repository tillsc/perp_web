xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.re :Ergebnisse, "xmlns:re" => "http://schemas.rudern.de/service/ergebnisse/2017/", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" do
  @results.keys.each do |race|
    xml.Rennen Nummer: race.number, Distanz: race.distance do
      @results[race].keys.each do |event|
        xml.Lauf Typ: event.type_short, Nummer: event.numeric_number, Bezeichnung: event.name do # Leistungsgruppe: "1"
          rank = 1
          last_rank = rank
          last_time = nil
          @results[race][event].
              sort_by { |r| r.time_for(race.finish_measuring_point).try(:time) || 'ZZZZZZZZZ' }.
              each do |result|
            xml.Boot Startnummer: result.participant.number do
              result.participant.all_rowers.each_with_index do |(position, rower), i|
                attrs = {Position: i+1}
                attrs[:istSteuermann] = true if (position == 9)
                attrs[:VereinsID] = rower.club_external_id if rower.club_external_id.to_i > 0
                attrs[:AktivenID] = rower.external_id if rower.external_id.present?
                xml.Sportler attrs do
                  xml.Nachname rower.last_name
                  xml.Vorname rower.first_name
                  xml.Jahrgang rower.year_of_birth.presence || 1900
                  xml.VereinsName rower.club_name if rower.club_name
                end
              end
              time = result.time_for(race.finish_measuring_point).try(:to_time)
              r = if (last_time == time)
                last_rank
              else
                last_rank = rank
              end
              xml.Ergebnis Rang: r, Zeit: time.strftime("PT%MM%S.%3NS")
              last_time = time
              rank+=1
              # <!-- DRV-WKR mit Lizenz nach "neuem" Schema -->
              # <Schiedsrichter Lizenznummer="2014123101"/>
            end
          end
        end
      end
    end
  end
end
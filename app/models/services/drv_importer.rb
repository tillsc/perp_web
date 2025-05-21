module Services
  class DrvImporter

    attr_reader :errors

    MANUAL_CLUB_SHORT_NAME_CORRECTIONS = {
      "Rudervereinigung Kappeln im Turn- und Sportverein Kappeln von 1876 e.V." => "RVg Kappeln"
    }

    def initialize(regatta)
      @regatta = regatta
      @errors = ActiveModel::Errors.new(self)
      @import_namespace = "drv"
    end

    def build_import(xml_data)
      import = Import.drv.new(regatta: @regatta)
      if xml_data.respond_to?(:read)
        xml_data = xml_data.read
      end
      import.xml = xml_data || "NO REAL XML!"
      execute(import, true)
    end

    def execute!(import)
      execute(import, false)
      import.imported_at = DateTime.now
    end

    protected

    def execute(import, preview)
      xml_doc = Nokogiri::XML(import.xml)

      meldungen_xml = xml_doc.root
      import.metadata = load_metadata(meldungen_xml)
      import.results = process(meldungen_xml, preview)

      import
    rescue Nokogiri::XML::SyntaxError
      import.metadata = nil
      import.results = nil
      self.errors.add(:base, "XML konnte nicht gelesen werden.")

      import
    end

    def load_metadata(meldungen_xml)
      { exported_at: DateTime.parse(meldungen_xml['stand']) }
    end

    def process(meldungen_xml, preview)
      events = @regatta.events.
        preload(participants: [:team, **Participant::ALL_ROWERS_WITH_CLUBS])
      teams = @regatta.teams.all.to_a
      rowers_with_external_ids = Rower.where.not(external_id: [nil, ""]).to_a
      rower_nn = Rower.nomen_nominandum
      seen_external_ids = []

      result = {representatives: {}, clubs: {}, participants: [], withdrawn_participant_external_ids: []}

      representatives = process_representatives(result, meldungen_xml, preview)
      clubs = process_clubs(result, meldungen_xml, preview)

      meldungen_xml.xpath("./meldungen/rennen").each do |rennen_xml|
        event_number = rennen_xml["nummer"].to_s
        event = events.find { |e| e.number.to_s == event_number } || raise("Entry #{entry["id"].inspect}: Could not find event #{event_number.inspect}")

        rennen_xml.xpath("./meldung").each do |meldung_xml|
          changed = false
          participant = event.participants.find { |p| p.imported_from == @import_namespace && p.external_id == meldung_xml["id"] }
          if !participant
            participant = event.participants.build(imported_from: @import_namespace, external_id: meldung_xml["id"])
            changed = true
          end
          seen_external_ids << meldung_xml["id"]

          representative_external_id = meldung_xml["obmann"].presence
          representative = representative_external_id && representatives[representative_external_id]
          if representative_external_id && representative.blank?
            raise("Meldung #{meldung_xml["id"]}: Konnte Obmann #{representative_external_id.inspect} nicht finden!")
          end

          team_name = Team.sanitize_name(
            process_club_names(meldung_xml.at_xpath("./titel").text),
            slashes_had_no_whitespace: true)
          existing_other_team = teams.find { |t|
            t.team_id != participant.team_id &&
              t.name == team_name &&
              t.representative_id == representative&.id
          }
          if participant.team.present?
            unless participant.team.name == team_name && participant.team.representative_id == representative&.id
              # Team has changed: See if we should change the existing team or create/assign a new one.
              unless participant.team.participants.count == 1 && existing_other_team.blank?
                # Team can't be changed since there is another participant using it or
                # there is no already existing one which should be used instead
                participant.team = nil # Remove assignment to trigger re-assignment
              end
            end
          end
          participant.team||= existing_other_team
          if !participant.team
            # Create new team
            participant.team = @regatta.teams.new(country: "GER")
            teams << participant.team
          end
          participant.team.name = team_name
          participant.team.representative = representative

          changed = true if participant.team.changed?
          if !preview
            participant.team.set_team_id
            participant.team.save
          else
            participant.team.valid?
          end
          self.errors.merge!(participant.team.errors) if participant.team.errors.any?

          rowers_data = meldung_xml.xpath("./mannschaft/position").inject({}) do |h, position|
            pos = position["st"] ? "s" : position["nr"]

            rower = participant.rower_at(pos)
            if position.children.any?
              external_id = position.at_xpath("./athlet")["id"]
              club_external_id = position.at_xpath("./athlet")["id"]
              first_name = position.at_xpath("./athlet/vorname").text
              last_name = position.at_xpath("./athlet/name").text
              year_of_birth = position.at_xpath("./athlet/jahrgang").text
              if external_id.present?
                if !rower || rower.external_id != external_id
                  rower = rowers_with_external_ids.find { |r| r.external_id == external_id }
                  rower||= Rower.find_by(first_name: first_name, last_name: last_name, year_of_birth: year_of_birth, external_id: [nil, ""])
                end
              else
                if !rower || rower.first_name != first_name || rower.last_name != last_name || rower.year_of_birth.to_s != year_of_birth
                  rower = Rower.find_by(first_name: first_name, last_name: last_name, year_of_birth: year_of_birth, external_id: [nil, ""])
                end
              end
              if !rower
                rower = Rower.new
                rowers_with_external_ids << rower
              end
              rower.first_name = first_name
              rower.last_name = last_name
              rower.year_of_birth = year_of_birth
              rower.external_id = external_id
              rower.club = clubs[club_external_id] if club_external_id.present?
              changed = true if rower.changed?
            elsif rower&.id != rower_nn.id
              changed = true
              rower = rower_nn
            else
              rower = rower_nn
            end
            rower_changes = rower.persisted? ? rower.changes : nil
            unless (preview ? rower.valid? : rower.save)
              self.errors.merge!(rower.errors)
            end

            participant.set_rower_at(pos, rower)

            h.merge(pos => rower.attributes.merge("what_changed" => rower_changes))
          end
          participant.entry_fee = participant.team.no_entry_fee? ? 0 : (event.entry_fee.to_f - participant.team.entry_fee_discount.to_f)

          participant.withdrawn = false
          participant.late_entry = !participant.persisted? && @regatta.entry_closed?

          changed = true if participant.changed?
          if changed
            participant.entry_changed = participant.persisted? && @regatta.entry_closed?
            if !preview
              participant.set_participant_id
              participant.save
            else
              participant.valid?
            end
            self.errors.merge!(participant.errors) if participant.errors.any?

            data = {
              event_number: event.number,
              participant_id: participant.participant_id&.nonzero?,
              participant_number: participant.number,
              team_id: participant.team.team_id&.nonzero?,
              team_name: participant.team.name,
              rowers: rowers_data,
              representative_external_id: representative_external_id,
              participant_attributes: participant.attributes.slice(*participant.changed).except("Regatta_ID", "Rennen"),
            }

            result[:participants] << data
          end
        end
      end

      to_be_withdrawn = @regatta.participants.enabled.
        where(imported_from: @import_namespace).
        where.not(external_id: seen_external_ids)
      to_be_withdrawn.each do |participant|
        result[:withdrawn_participant_external_ids] << participant.external_id
        if !preview
          participant.update(withdrawn: true)
        end
        self.errors.merge!(participant.errors) if participant.errors.any?
      end

      result
    end

    def process_representatives(result, meldungen_xml, preview)
      representatives = Address.representative.all

      meldungen_xml.xpath("./obleute/obmann").inject({}) do |h, obmann|
        obmann_name = obmann.at_xpath("./name").text
        representative = representatives.find do |r|
          r.name(first_name_last_name: true) == obmann_name &&
            (r.external_id.blank? || r.external_id.to_s == obmann["id"].to_s)
        end
        if !representative
          names = obmann_name.split(" ")
          last_name = names.pop
          if ["van", "von"].include?(names.last)
            last_name = "#{names.pop} last_name"
          end
          first_name = names.join(" ")
          representative = Address.representative.build(first_name: first_name, last_name: last_name)
        end
        representative.external_id = obmann["id"]
        representative.email = obmann.xpath("./email").text
        representative.telefone_mobile = obmann.xpath("./phone").text

        changed_attributes = representative.attributes.slice(*representative.changed)
        unless (preview ? representative.valid? : representative.save)
          self.errors.merge!(representative.errors)
        end

        result[:representatives][obmann["id"]] = changed_attributes.merge("id" => representative.id)

        h.merge(obmann["id"] => representative)
      end
    end

    def process_clubs(result, meldungen_xml, preview)
      clubs = Address.club.all

      meldungen_xml.xpath("./vereine/verein").inject({}) do |h, verein|
        verein_name = process_club_names(verein.at_xpath("./kurzform").text)
        verein_name_lang = verein.at_xpath("./name").text
        club = clubs.find { |c| c.external_id == verein["id"] }
        if !club
          club = Address.club.where(external_id: nil).
            find_or_initialize_by(first_name: verein_name_lang, last_name: verein_name)
        end
        club.external_id = verein["id"]
        club.first_name = verein_name_lang
        club.last_name = verein_name

        changed_attributes = club.attributes.slice(*club.changed)
        unless (preview ? club.valid? : club.save)
          self.errors.merge!(club.errors)
        end
        result[:clubs][verein["id"]] = changed_attributes.merge("id" => club.id)

        h.merge(verein["id"] => club)
      end
    end

    def process_club_names(s)
      MANUAL_CLUB_SHORT_NAME_CORRECTIONS.inject(s) do |s, (old, new)|
        s&.gsub(old, new)
      end
    end

  end
end

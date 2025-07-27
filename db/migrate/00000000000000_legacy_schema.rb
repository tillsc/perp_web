class LegacySchema < ActiveRecord::Migration[5.2]

  def mysql_unsigned
    if ActiveRecord::Base.connection.adapter_name.downcase.include?("mysql")
      { unsigned: true }
    else
      {}
    end
  end

  def change

    create_table "addressen", primary_key: "ID", id: :integer, force: :cascade do |t|
      t.string "Titel", limit: 10
      t.string "Vorname", limit: 100
      t.string "Name", limit: 200
      t.string "Namenszusatz", limit: 100
      t.boolean "Weiblich", default: false
      t.string "ExterneID1", limit: 20
      t.string "Strasse", limit: 35
      t.string "PLZ", limit: 10
      t.string "Ort", limit: 35
      t.string "Land", limit: 25
      t.string "Telefon_Privat", limit: 20
      t.string "Telefon_Geschaeftlich", limit: 20
      t.string "Telefon_Mobil", limit: 20
      t.string "Fax", limit: 20
      t.string "eMail", limit: 40
      t.boolean "IstVerein", default: false, null: false
      t.boolean "IstSchiedsrichter", default: false, null: false
      t.boolean "IstObmann", default: false, null: false
      t.boolean "IstRegattastab", default: false, null: false
      t.string "PublicPrivateID", limit: 80
    end

    create_table "ergebnisse", primary_key: ["Regatta_ID", "Rennen", "Lauf", "TNr"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Rennen", default: 0, null: false, **mysql_unsigned
      t.string "Lauf", limit: 2, default: "", null: false
      t.integer "TNr", default: 0, null: false
      t.integer "Bahn", limit: 3, **mysql_unsigned
      t.boolean "Ausgeschieden", default: false, null: false
      t.string "Kommentar"
      t.index ["Regatta_ID", "Rennen", "Lauf"]
    end

    create_table "gewichte", primary_key: "ID", id: { type: :integer, **mysql_unsigned }, force: :cascade do |t|
      t.integer "Ruderer_ID", default: 0, null: false, **mysql_unsigned
      t.datetime "Datum", null: false
      t.float "Gewicht", default: 0.0, null: false
      t.index ["Datum"], name: "Datum"
      t.index ["Ruderer_ID", "Datum"], name: "Eindeutig", unique: true
      t.index ["Ruderer_ID"], name: "Ruderer_IDs"
    end

    create_table "laeufe", primary_key: "ID", id: { type: :integer, **mysql_unsigned }, force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Rennen", default: 0, null: false, **mysql_unsigned
      t.string "Lauf", limit: 3, default: "", null: false
      t.time "IstStartZeit"
      t.datetime "SollStartZeit"
      t.integer "Schiedsrichter_ID_Starter", **mysql_unsigned
      t.integer "Schiedsrichter_ID_Aligner", **mysql_unsigned
      t.integer "Schiedsrichter_ID_Umpire", **mysql_unsigned
      t.integer "Schiedsrichter_ID_Judge", **mysql_unsigned
      t.integer "ErgebnisKorrigiert", limit: 2, default: 0, null: false, **mysql_unsigned
      t.datetime "WiegelisteFreigegeben"
      t.string "WiegelisteFreigegebenVon", limit: 150
      t.datetime "ErgebnisEndgueltig"
      t.index ["Regatta_ID", "Rennen", "Lauf"], name: "UNIQUE", unique: true
    end

    create_table "meldungen", primary_key: ["Regatta_ID", "Rennen", "TNr"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Rennen", default: 0, null: false
      t.integer "TNr", default: 0, null: false
      t.integer "Team_ID", **mysql_unsigned
      t.integer "TeamBoot", limit: 1, **mysql_unsigned
      t.integer "BugNr"
      t.integer "Meldegeld", limit: 3, **mysql_unsigned
      t.boolean "Abgemeldet", default: false
      t.boolean "Umgemeldet", default: false
      t.boolean "Nachgemeldet", default: false
      t.string "Ausgeschieden", limit: 100
      t.integer "ruderer1_ID", **mysql_unsigned
      t.integer "ruderer2_ID", **mysql_unsigned
      t.integer "ruderer3_ID", **mysql_unsigned
      t.integer "ruderer4_ID", **mysql_unsigned
      t.integer "ruderer5_ID", **mysql_unsigned
      t.integer "ruderer6_ID", **mysql_unsigned
      t.integer "ruderer7_ID", **mysql_unsigned
      t.integer "ruderer8_ID", **mysql_unsigned
      t.integer "ruderers_ID", **mysql_unsigned
      t.text "Historie"
      t.index ["Team_ID"]
    end

    create_table "messpunkte", primary_key: ["Regatta_ID", "MesspunktNr"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "MesspunktNr", limit: 2, default: 0, null: false, **mysql_unsigned
      t.integer "Position", default: 0, null: false, **mysql_unsigned
    end

    create_table "parameter", primary_key: ["Sektion", "Schluessel"], force: :cascade do |t|
      t.string "Sektion", limit: 40, default: "", null: false
      t.string "Schluessel", limit: 40, default: "", null: false
      t.string "Wert", limit: 100
      t.text "Zusatz"
    end

    create_table "regatten", primary_key: "ID", id: { type: :integer, **mysql_unsigned }, force: :cascade do |t|
      t.integer "Jahr", default: 0, null: false, **mysql_unsigned
      t.string "Kurzbezeichnung", limit: 10, default: "", null: false
      t.string "DefName"
      t.integer "Veranstalter_ID", default: 0, null: false, **mysql_unsigned
      t.string "Veranstalter", limit: 100, default: "", null: false
      t.string "Waehrung", limit: 10, default: "€"
      t.integer "ZwischenStrecke", default: 250, null: false, **mysql_unsigned
      t.string "Hash", limit: 100, default: "", null: false
      t.date "StartDatum", null: false
      t.date "EndDatum", null: false
      t.index ["Jahr", "Kurzbezeichnung"], unique: true
    end

    create_table "rennen", primary_key: ["Regatta_ID", "Rennen"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Rennen", default: 0, null: false
      t.string "NameK", limit: 20
      t.string "NameD", limit: 100
      t.string "NameE", limit: 100
      t.integer "Startgeld"
      t.string "Regattaname", limit: 100
      t.integer "StartMesspunktNr", default: 0, null: false, **mysql_unsigned
      t.integer "ZielMesspunktNr", default: 8, null: false, **mysql_unsigned
      t.integer "RudererAnzahl", limit: 1, **mysql_unsigned
      t.boolean "MitSteuermann", default: false, null: false
      t.boolean "Leichtgewicht", default: false, null: false
      t.float "MaximalesDurchschnittgewicht", **mysql_unsigned
      t.float "MaximalesEinzelgewicht", **mysql_unsigned
      t.float "MinimalesSteuermanngewicht", **mysql_unsigned
      t.text "Zusatztext1"
      t.integer "Zusatztext1Format", limit: 1, default: 0, null: false, **mysql_unsigned
    end

    create_table "ruderer", primary_key: "ID", id: { type: :integer, **mysql_unsigned }, force: :cascade do |t|
      t.string "VName", limit: 20, default: "", null: false
      t.string "NName", limit: 50, default: "", null: false
      t.string "JahrG", limit: 4, default: "", null: false
      t.integer "Verein_ID", **mysql_unsigned
      t.string "ExterneID1", limit: 20
      t.boolean "HoehereZulassung", default: false, null: false
      t.string "Startberechtigt", limit: 50
      t.string "Zusatz", limit: 100
      t.datetime "AenderungsDatum", null: false
      t.index ["NName", "VName", "JahrG"]
    end

    create_table "schiedsrichterliste", primary_key: ["Regatta_ID", "Schiedsrichter_ID"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Schiedsrichter_ID", default: 0, null: false, **mysql_unsigned
    end

    create_table "startlisten", primary_key: ["Regatta_ID", "Rennen", "Lauf", "Bahn"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Rennen", default: 0, null: false
      t.string "Lauf", limit: 2, default: "", null: false
      t.integer "Bahn", default: 0, null: false
      t.integer "TNr", default: 0, null: false
    end

    create_table "teams", primary_key: ["Regatta_ID", "ID"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "ID", default: 0, null: false, **mysql_unsigned
      t.string "Land", limit: 4
      t.string "Stadt", limit: 50
      t.text "Teamname"
      t.integer "Obmann_ID", **mysql_unsigned
      t.boolean "Meldegeldbefreit", default: false, null: false
      t.integer "Meldegeldrabatt", limit: 1, default: 0, null: false, **mysql_unsigned
    end

    create_table "veranstalter", primary_key: "ID", id: { type: :integer, **mysql_unsigned }, force: :cascade do |t|
      t.string "Name", limit: 200, default: "", null: false
      t.text "BriefkopfRechts"
      t.string "BriefkopfAbsender"
      t.text "BriefFuss"
    end

    create_table "zeiten", primary_key: ["Regatta_ID", "Rennen", "Lauf", "TNr", "MesspunktNr"], force: :cascade do |t|
      t.integer "Regatta_ID", default: 0, null: false, **mysql_unsigned
      t.integer "Rennen", default: 0, null: false, **mysql_unsigned
      t.string "Lauf", limit: 2, default: "", null: false
      t.integer "TNr", default: 0, null: false
      t.integer "MesspunktNr", default: 0, null: false
      t.string "Zeit", limit: 13
      t.index ["Regatta_ID", "Rennen", "Lauf"]
    end
  end

end

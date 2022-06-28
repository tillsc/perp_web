# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_06_28_125714) do

  create_table "addressen", primary_key: "ID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "Titel", limit: 10
    t.string "Vorname", limit: 100
    t.string "Name", limit: 200
    t.string "Namenszusatz", limit: 100
    t.integer "Weiblich", limit: 1, default: 0, unsigned: true
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
    t.integer "IstVerein", limit: 1, default: 0, null: false, unsigned: true
    t.integer "IstSchiedsrichter", limit: 1, default: 0, null: false, unsigned: true
    t.integer "IstObmann", limit: 1, default: 0, null: false, unsigned: true
    t.integer "IstRegattastab", limit: 1, default: 0, null: false, unsigned: true
    t.string "PublicPrivateID", limit: 80
  end

  create_table "crexport", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "GH1_programmheft_RennName", limit: 42
    t.string "GH1_2", limit: 11
    t.string "GH1_programmheft_RennNameD"
    t.string "GH1_programmheft_RennNameE"
    t.text "GH1_programmheft_Zusatztext1", limit: 16777215
    t.string "GH1_6", limit: 34
    t.integer "DE_programmheft_BugNr"
    t.string "DE_programmheft_Land", limit: 10
    t.string "DE_3"
    t.string "DE_Namen"
    t.string "GF1_1", limit: 37
    t.string "PF_1", limit: 34
  end

  create_table "ergebnisse", primary_key: ["Regatta_ID", "Rennen", "Lauf", "TNr"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false, unsigned: true
    t.string "Lauf", limit: 2, default: "", null: false
    t.integer "TNr", default: 0, null: false
    t.integer "Bahn", limit: 3, unsigned: true
    t.integer "Ausgeschieden", limit: 1, default: 0, null: false, unsigned: true
    t.string "Kommentar"
    t.index ["Regatta_ID", "Rennen", "Lauf"], name: "SECONDARY"
  end

  create_table "gewichte", primary_key: "ID", id: :integer, unsigned: true, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Ruderer_ID", default: 0, null: false, unsigned: true
    t.datetime "Datum", null: false
    t.float "Gewicht", default: 0.0, null: false
    t.index ["Datum"], name: "Datum"
    t.index ["Ruderer_ID", "Datum"], name: "Eindeutig", unique: true
    t.index ["Ruderer_ID"], name: "Ruderer_IDs"
  end

  create_table "laeufe", primary_key: "ID", id: :integer, unsigned: true, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false, unsigned: true
    t.string "Lauf", limit: 3, default: "", null: false
    t.time "IstStartZeit"
    t.datetime "SollStartZeit"
    t.integer "Schiedsrichter_ID_Starter", unsigned: true
    t.integer "Schiedsrichter_ID_Aligner", unsigned: true
    t.integer "Schiedsrichter_ID_Umpire", unsigned: true
    t.integer "Schiedsrichter_ID_Judge", unsigned: true
    t.integer "ErgebnisKorrigiert", limit: 2, default: 0, null: false, unsigned: true
    t.datetime "WiegelisteFreigegeben"
    t.string "WiegelisteFreigegebenVon", limit: 150
    t.datetime "ErgebnisEndgueltig"
    t.index ["Regatta_ID", "Rennen", "Lauf"], name: "UNIQUE", unique: true
  end

  create_table "measurement_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "measuring_session_id"
    t.integer "Regatta_ID", null: false
    t.integer "Rennen", null: false
    t.string "Lauf", limit: 2, null: false
    t.integer "MesspunktNr"
    t.text "measurements"
    t.text "measurements_history"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "measuring_sessions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "device_description"
    t.integer "Regatta_ID"
    t.integer "MesspunktNr"
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meldungen", primary_key: ["Regatta_ID", "Rennen", "TNr"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false
    t.integer "TNr", default: 0, null: false
    t.integer "Team_ID", unsigned: true
    t.integer "TeamBoot", limit: 1, unsigned: true
    t.integer "BugNr"
    t.integer "Meldegeld", limit: 3, unsigned: true
    t.boolean "Abgemeldet", default: false
    t.boolean "Umgemeldet", default: false
    t.boolean "Nachgemeldet", default: false
    t.string "Ausgeschieden", limit: 100
    t.integer "ruderer1_ID", unsigned: true
    t.integer "ruderer2_ID", unsigned: true
    t.integer "ruderer3_ID", unsigned: true
    t.integer "ruderer4_ID", unsigned: true
    t.integer "ruderer5_ID", unsigned: true
    t.integer "ruderer6_ID", unsigned: true
    t.integer "ruderer7_ID", unsigned: true
    t.integer "ruderer8_ID", unsigned: true
    t.integer "ruderers_ID", unsigned: true
    t.text "Historie"
    t.index ["Team_ID"], name: "SECONDARY"
  end

  create_table "messpunkte", primary_key: ["Regatta_ID", "MesspunktNr"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "MesspunktNr", limit: 2, default: 0, null: false, unsigned: true
    t.integer "Position", default: 0, null: false, unsigned: true
    t.integer "measuring_session_id"
  end

  create_table "parameter", primary_key: ["Sektion", "Schluessel"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "Sektion", limit: 40, default: "", null: false
    t.string "Schluessel", limit: 40, default: "", null: false
    t.string "Wert", limit: 100
    t.text "Zusatz"
  end

  create_table "regatten", primary_key: "ID", id: :integer, unsigned: true, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Jahr", default: 0, null: false, unsigned: true
    t.string "Kurzbezeichnung", limit: 10, default: "", null: false
    t.string "DefName"
    t.integer "Veranstalter_ID", default: 0, null: false, unsigned: true
    t.string "Veranstalter", limit: 100, default: "", null: false
    t.string "Waehrung", limit: 10, default: "€"
    t.integer "ZwischenStrecke", default: 250, null: false, unsigned: true
    t.string "Hash", limit: 100, default: "", null: false
    t.date "StartDatum", null: false
    t.date "EndDatum", null: false
    t.index ["Jahr", "Kurzbezeichnung"], name: "SECONDARY", unique: true
  end

  create_table "rennen", primary_key: ["Regatta_ID", "Rennen"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false
    t.string "NameK", limit: 20
    t.string "NameD", limit: 100
    t.string "NameE", limit: 100
    t.integer "Startgeld"
    t.string "Regattaname", limit: 100
    t.integer "StartMesspunktNr", default: 0, null: false, unsigned: true
    t.integer "ZielMesspunktNr", default: 8, null: false, unsigned: true
    t.integer "RudererAnzahl", limit: 1, unsigned: true
    t.integer "MitSteuermann", limit: 1, unsigned: true
    t.integer "Leichtgewicht", limit: 1, default: 0, null: false, unsigned: true
    t.float "MaximalesDurchschnittgewicht", unsigned: true
    t.float "MaximalesEinzelgewicht", unsigned: true
    t.float "MinimalesSteuermanngewicht", unsigned: true
    t.text "Zusatztext1"
    t.integer "Zusatztext1Format", limit: 1, default: 0, null: false, unsigned: true
  end

  create_table "ruderer", primary_key: "ID", id: :integer, unsigned: true, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "VName", limit: 20, default: "", null: false
    t.string "NName", limit: 50, default: "", null: false
    t.string "JahrG", limit: 4, default: "", null: false
    t.integer "Verein_ID", unsigned: true
    t.string "ExterneID1", limit: 20
    t.integer "HoehereZulassung", limit: 1, default: 0, null: false, unsigned: true
    t.string "Startberechtigt", limit: 50
    t.string "Zusatz", limit: 100
    t.datetime "AenderungsDatum", null: false
    t.index ["NName", "VName", "JahrG"], name: "SECONDARY"
  end

  create_table "schiedsrichterliste", primary_key: ["Regatta_ID", "Schiedsrichter_ID"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Schiedsrichter_ID", default: 0, null: false, unsigned: true
  end

  create_table "startlisten", primary_key: ["Regatta_ID", "Rennen", "Lauf", "Bahn"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false
    t.string "Lauf", limit: 2, default: "", null: false
    t.integer "Bahn", default: 0, null: false
    t.integer "TNr", default: 0, null: false
  end

  create_table "teams", primary_key: ["Regatta_ID", "ID"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "ID", default: 0, null: false, unsigned: true
    t.string "Land", limit: 4
    t.string "Stadt", limit: 50
    t.text "Teamname"
    t.integer "Obmann_ID", unsigned: true
    t.integer "Meldegeldbefreit", limit: 1, default: 0, null: false, unsigned: true
    t.integer "Meldegeldrabatt", limit: 1, default: 0, null: false, unsigned: true
  end

  create_table "veranstalter", primary_key: "ID", id: :integer, unsigned: true, options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "Name", limit: 200, default: "", null: false
    t.text "BriefkopfRechts"
    t.string "BriefkopfAbsender"
    t.text "BriefFuss"
  end

  create_table "zeiten", primary_key: ["Regatta_ID", "Rennen", "Lauf", "TNr", "MesspunktNr"], options: "ENGINE=MyISAM DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false, unsigned: true
    t.string "Lauf", limit: 2, default: "", null: false
    t.integer "TNr", default: 0, null: false
    t.integer "MesspunktNr", default: 0, null: false
    t.string "Zeit", limit: 13
    t.index ["Regatta_ID", "Rennen", "Lauf"], name: "SECONDARY"
  end

end

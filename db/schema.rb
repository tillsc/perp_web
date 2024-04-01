# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_03_31_153203) do
  create_table "addressen", primary_key: "ID", id: :integer, charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
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

  create_table "crexport", id: false, charset: "latin1", force: :cascade do |t|
    t.string "GH1_programmheft_RennName", limit: 42
    t.string "GH1_2", limit: 11
    t.string "GH1_programmheft_RennNameD"
    t.string "GH1_programmheft_RennNameE"
    t.text "GH1_programmheft_Zusatztext1", size: :medium
    t.string "GH1_6", limit: 34
    t.integer "DE_programmheft_BugNr"
    t.string "DE_programmheft_Land", limit: 10
    t.string "DE_3"
    t.string "DE_Namen"
    t.string "GF1_1", limit: 37
    t.string "PF_1", limit: 34
  end

  create_table "ergebnisse", primary_key: ["Regatta_ID", "Rennen", "Lauf", "TNr"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false, unsigned: true
    t.string "Lauf", limit: 2, default: "", null: false
    t.integer "TNr", default: 0, null: false
    t.integer "Bahn", limit: 3, unsigned: true
    t.integer "Ausgeschieden", limit: 1, default: 0, null: false, unsigned: true
    t.string "Kommentar"
    t.index ["Regatta_ID", "Rennen", "Lauf"], name: "SECONDARY"
  end

  create_table "gewichte", primary_key: "ID", id: { type: :integer, unsigned: true }, charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Ruderer_ID", default: 0, null: false, unsigned: true
    t.datetime "Datum", precision: nil, null: false
    t.float "Gewicht", default: 0.0, null: false
    t.index ["Datum"], name: "Datum"
    t.index ["Ruderer_ID", "Datum"], name: "Eindeutig", unique: true
    t.index ["Ruderer_ID"], name: "Ruderer_IDs"
  end

  create_table "laeufe", primary_key: "ID", id: { type: :integer, unsigned: true }, charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false, unsigned: true
    t.string "Lauf", limit: 3, default: "", null: false
    t.time "IstStartZeit"
    t.datetime "SollStartZeit", precision: nil
    t.integer "Schiedsrichter_ID_Starter", unsigned: true
    t.integer "Schiedsrichter_ID_Aligner", unsigned: true
    t.integer "Schiedsrichter_ID_Umpire", unsigned: true
    t.integer "Schiedsrichter_ID_Judge", unsigned: true
    t.integer "ErgebnisKorrigiert", limit: 2, default: 0, null: false, unsigned: true
    t.datetime "WiegelisteFreigegeben", precision: nil
    t.string "WiegelisteFreigegebenVon", limit: 150
    t.datetime "ErgebnisEndgueltig", precision: nil
    t.index ["Regatta_ID", "Rennen", "Lauf"], name: "UNIQUE", unique: true
  end

  create_table "measurement_sets", charset: "utf8", force: :cascade do |t|
    t.integer "measuring_session_id"
    t.integer "Regatta_ID", null: false
    t.integer "Rennen", null: false
    t.string "Lauf", limit: 2, null: false
    t.integer "MesspunktNr"
    t.text "measurements"
    t.text "measurements_history"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "measuring_sessions", charset: "utf8", force: :cascade do |t|
    t.string "device_description"
    t.integer "Regatta_ID"
    t.integer "MesspunktNr"
    t.string "identifier"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "autoreload_disabled"
    t.boolean "hide_team_names"
  end

  create_table "meldungen", primary_key: ["Regatta_ID", "Rennen", "TNr"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
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
    t.index ["BugNr"], name: "index_meldungen_on_bugnr"
    t.index ["Team_ID"], name: "SECONDARY"
    t.index ["ruderer1_ID"], name: "index_meldungen_on_ruderer1_ID"
    t.index ["ruderer2_ID"], name: "index_meldungen_on_ruderer2_ID"
    t.index ["ruderer3_ID"], name: "index_meldungen_on_ruderer3_ID"
    t.index ["ruderer4_ID"], name: "index_meldungen_on_ruderer4_ID"
    t.index ["ruderer5_ID"], name: "index_meldungen_on_ruderer5_ID"
    t.index ["ruderer6_ID"], name: "index_meldungen_on_ruderer6_ID"
    t.index ["ruderer7_ID"], name: "index_meldungen_on_ruderer7_ID"
    t.index ["ruderer8_ID"], name: "index_meldungen_on_ruderer8_ID"
    t.index ["ruderers_ID"], name: "index_meldungen_on_ruderers_ID"
  end

  create_table "messpunkte", primary_key: ["Regatta_ID", "MesspunktNr"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "MesspunktNr", limit: 2, default: 0, null: false, unsigned: true
    t.integer "Position", default: 0, null: false, unsigned: true
    t.integer "measuring_session_id"
  end

  create_table "parameter", primary_key: ["Sektion", "Schluessel"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "Sektion", limit: 40, default: "", null: false
    t.string "Schluessel", limit: 40, default: "", null: false
    t.string "Wert", limit: 100
    t.text "Zusatz"
  end

  create_table "regatten", primary_key: "ID", id: { type: :integer, unsigned: true }, charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
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

  create_table "rennen", primary_key: ["Regatta_ID", "Rennen"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
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

  create_table "ruderer", primary_key: "ID", id: { type: :integer, unsigned: true }, charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "VName", limit: 20, default: "", null: false
    t.string "NName", limit: 50, default: "", null: false
    t.string "JahrG", limit: 4, default: "", null: false
    t.integer "Verein_ID", unsigned: true
    t.string "ExterneID1", limit: 20
    t.integer "HoehereZulassung", limit: 1, default: 0, null: false, unsigned: true
    t.string "Startberechtigt", limit: 50
    t.string "Zusatz", limit: 100
    t.datetime "AenderungsDatum", precision: nil, null: false
    t.index ["ExterneID1"], name: "index_ruderer_on_ExterneID1"
    t.index ["JahrG"], name: "index_ruderer_on_JahrG"
    t.index ["NName", "VName", "JahrG"], name: "SECONDARY"
    t.index ["VName"], name: "index_ruderer_on_VName"
    t.index ["Verein_ID"], name: "index_ruderer_on_Verein_ID"
  end

  create_table "schiedsrichterliste", primary_key: ["Regatta_ID", "Schiedsrichter_ID"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Schiedsrichter_ID", default: 0, null: false, unsigned: true
  end

  create_table "startlisten", primary_key: ["Regatta_ID", "Rennen", "Lauf", "Bahn"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false
    t.string "Lauf", limit: 2, default: "", null: false
    t.integer "Bahn", default: 0, null: false
    t.integer "TNr", default: 0, null: false
  end

  create_table "teams", primary_key: ["Regatta_ID", "ID"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "ID", default: 0, null: false, unsigned: true
    t.string "Land", limit: 4
    t.string "Stadt", limit: 50
    t.text "Teamname"
    t.integer "Obmann_ID", unsigned: true
    t.integer "Meldegeldbefreit", limit: 1, default: 0, null: false, unsigned: true
    t.integer "Meldegeldrabatt", limit: 1, default: 0, null: false, unsigned: true
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.text "roles"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "veranstalter", primary_key: "ID", id: { type: :integer, unsigned: true }, charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.string "Name", limit: 200, default: "", null: false
    t.text "BriefkopfRechts"
    t.string "BriefkopfAbsender"
    t.text "BriefFuss"
  end

  create_table "zeiten", primary_key: ["Regatta_ID", "Rennen", "Lauf", "TNr", "MesspunktNr"], charset: "latin1", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "Regatta_ID", default: 0, null: false, unsigned: true
    t.integer "Rennen", default: 0, null: false, unsigned: true
    t.string "Lauf", limit: 2, default: "", null: false
    t.integer "TNr", default: 0, null: false
    t.integer "MesspunktNr", default: 0, null: false
    t.string "Zeit", limit: 13
    t.index ["Regatta_ID", "Rennen", "Lauf"], name: "SECONDARY"
  end

end

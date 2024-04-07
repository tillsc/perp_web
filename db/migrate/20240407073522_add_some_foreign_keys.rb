class AddSomeForeignKeys < ActiveRecord::Migration[7.1]
  def up
    execute(<<sql)
ALTER TABLE rennen
  ADD CONSTRAINT fk_rennen_regatten
  FOREIGN KEY (Regatta_ID) 
  REFERENCES regatten (Regatta_ID) ON DELETE RESTRICT
sql

    execute(<<sql)
ALTER TABLE meldungen
  ADD CONSTRAINT fk_meldungen_rennen 
  FOREIGN KEY (Regatta_ID, Rennen) 
  REFERENCES rennen (Regatta_ID, Rennen) ON DELETE RESTRICT
sql

    execute(<<sql)
ALTER TABLE startlisten
  ADD CONSTRAINT fk_startlisten_laeufe 
  FOREIGN KEY (Regatta_ID, Rennen, Lauf) 
  REFERENCES laeufe (Regatta_ID, Rennen, Lauf) ON DELETE RESTRICT
sql
    execute(<<sql)
ALTER TABLE ergebnisse
  ADD CONSTRAINT fk_ergebnisse_laeufe 
  FOREIGN KEY (Regatta_ID, Rennen, Lauf) 
  REFERENCES laeufe (Regatta_ID, Rennen, Lauf) ON DELETE RESTRICT
sql
  end

  def down
    execute('ALTER TABLE rennen DROP FOREIGN KEY fk_rennen_regatten')

    execute('ALTER TABLE meldungen DROP FOREIGN KEY fk_meldungen_rennen')

    execute('ALTER TABLE startlisten DROP FOREIGN KEY fk_startlisten_laeufe')
    execute('ALTER TABLE ergebnisse DROP FOREIGN KEY fk_ergebnisse_laeufe')
  end
end

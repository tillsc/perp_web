# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
[["Global", "LauftypenNachMeldeergebnis", "AV", nil],
 ["Global", "LauftypSortierung", "AZVHXYOQSKF", nil],
 ["Uebersetzer_Lauftypen", "A", "Abteilung", "Abteilungen"],
 ["Uebersetzer_Lauftypen", "F", "Finale", "Finals"],
 ["Uebersetzer_Lauftypen", "H", "Hoffnugslauf", "Hoffnungsläufe"],
 ["Uebersetzer_Lauftypen", "K", "Kleines Finale", "Kleine Finals"],
 ["Uebersetzer_Lauftypen", "O", "Achtelfinale", "Achtelfinals"],
 ["Uebersetzer_Lauftypen", "Q", "Viertelfinale", "Viertelfinals"],
 ["Uebersetzer_Lauftypen", "S", "Halbfinale", "Halbfinals"],
 ["Uebersetzer_Lauftypen", "V", "Vorlauf", "Vorläufe"],
 ["Uebersetzer_Lauftypen", "X", "2. Hoffnungslauf", "2. Hoffnungsläufe"],
 ["Uebersetzer_Lauftypen", "Y", "Hauptlauf", "Hauptläufe"],
 ["Uebersetzer_Lauftypen", "Z", "Zwischenlauf", "Zwischenläufe"]
].each do |(section, key, value, additional)|
  Parameter.
    create_with(value: value, additional: additional).
    find_or_create_by(section: section, key: key)
end

if User.all.none?
  puts "No users present in the database. Creating initial admin user."
  admin_email = ENV.fetch('INITIAL_ADMIN_EMAIL', "admin@localhost")
  admin_password = ENV.fetch('INITIAL_ADMIN_PASSWORD') do
    pw = SecureRandom.hex(16)
    puts "[WARN] No INITIAL_ADMIN_PASSWORD found. Generated random password: #{pw.inspect}. Please change the password as soon as possible."
    pw
  end
  u = User.create!(email: admin_email, password: admin_password, password_confirmation: admin_password, roles: ['admin'])
  u.confirm
  puts "User #{u.email.inspect} created."
end

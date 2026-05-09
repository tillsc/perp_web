namespace :db do
  desc "List all MyISAM tables in the current database"
  task myisam_tables: :environment do
    tables = myisam_table_names
    if tables.empty?
      puts "No MyISAM tables found."
    else
      puts "MyISAM tables (#{tables.size}):"
      tables.each { |t| puts "  #{t}" }
    end
  end

  desc "Convert all MyISAM tables to InnoDB (run myisam_tables first to preview)"
  task convert_to_innodb: :environment do
    tables = myisam_table_names
    if tables.empty?
      puts "No MyISAM tables found, nothing to do."
      next
    end

    puts "Converting #{tables.size} table(s) to InnoDB..."
    conn = ActiveRecord::Base.connection
    original_mode = conn.execute("SELECT @@SESSION.sql_mode").first.first
    conn.execute("SET SESSION sql_mode = ''")
    tables.each do |table|
      print "  #{table} ... "
      conn.execute("ALTER TABLE `#{table}` ENGINE=InnoDB")
      puts "done"
    end
    conn.execute("SET SESSION sql_mode = #{conn.quote(original_mode)}")
    puts "Finished. Run `rails db:schema:dump` to update schema.rb."
  end

  def myisam_table_names
    ActiveRecord::Base.connection.execute(
      "SELECT table_name FROM information_schema.tables
       WHERE table_schema = DATABASE() AND engine = 'MyISAM'
       ORDER BY table_name"
    ).map(&:first)
  end
end

class Dbconnection
  CURRENT_DIR = File.dirname(__FILE__)
  DB_FILE = CURRENT_DIR + '/../db/database.yml'

  def setup_db
    dbconfig = YAML::load(File.open(DB_FILE))
    ActiveRecord::Base.establish_connection(dbconfig)
  end
end

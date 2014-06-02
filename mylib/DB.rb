require 'sqlite3'
class DB
    def initialize(db)
        fail "Database not exist - #{db}" if not File.exist? db
        @db = SQLite3::Database.new( db )
    end

    def insert_flag(token, team_id, service_id, round)
        @db.execute( "insert into FLAG (value, team_id, service_id, round) values (:token, :team_id, :service_id, :round)",
        "token" => token,
        "team_id" => team_id,
        "service_id" => service_id,
        "round" => round)
    end
end


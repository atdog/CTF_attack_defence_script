require 'sqlite3'
class DB
    def initialize(db)
        fail "Database not exist - #{db}" if not File.exist? db
        @db = SQLite3::Database.open( db )
    end

    def insert_flag(token, team_id, service_id, round)
        @db.execute( "insert into FLAG (value, team_id, service_id, round) values (:token, :team_id, :service_id, :round)",
        "token" => token,
        "team_id" => team_id,
        "service_id" => service_id,
        "round" => round)
    end

    def each_team
        begin
            teams = @db.execute("select * from teams")
        rescue
            fail "Query teams error" 
        end

        teams.each do |team|
            yield team
        end
    end
end


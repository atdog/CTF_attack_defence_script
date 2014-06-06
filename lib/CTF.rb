require_relative "Workstation"
require_relative "AdminConfig"

require "sqlite3"

class CTF
    attr_accessor :teams, :workstations, :ctf_id
    
    def initialize(ctf_id)
        @ctf_id = ctf_id
        validate_ctf
        init_teams
        init_workstations
    end

    def validate_ctf
        db = AdminConfig.db
        fail "Database not exist - #{db}" if not File.exist? db
        db = SQLite3::Database.open( db )

        begin
            ctfs = db.execute( "select * from ctfs where id = :id", "id" => @ctf_id)
        rescue
            fail "Query ctfs error" 
        end

        fail "No CTF id - #{@ctf_id}" if ctfs == nil
        puts "[+] CTF #{ctfs[0][1]} - id: #{@ctf_id}"
    end

    def init_teams
        db = AdminConfig.db
        fail "Database not exist - #{db}" if not File.exist? db
        db = SQLite3::Database.open( db )

        begin
            teams = db.execute("select * from teams where id in (select team_id from attendents where ctf_id = :ctfid)", "ctfid" => @ctf_id)
        rescue
            fail "Query teams error" 
        end

        @teams = []
        teams.each do |team|
            @teams.push({ "id" => team[0], "name" => team[1], "ip" => team[2] })
            break
        end
    end

    def init_workstations
        @workstations = []
        @teams.each do |team|
            team["workstation"] = Workstation.new(@ctf_id, team["id"], team["ip"])
            @workstations.push team["Workstation"]
        end
    end

    def each_team
        @teams.each do |team|
            yield team
        end
    end

    def each_workstation
        @workstations.each do |workstation|
            yield workstation
        end
    end

    private :init_teams, :init_workstations, :validate_ctf
end

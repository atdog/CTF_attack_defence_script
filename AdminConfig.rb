class AdminConfig
    class << self; attr_accessor :db, :challenger, :root_privatekey end

    @db = "/ctf/scoreboard/db/scoreboard.sqlite3"
    @challenger = "user"
    @root_privatekey = "/home/atdog/admin_script/id_rsa"
end

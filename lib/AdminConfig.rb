class AdminConfig
    class << self; attr_accessor :db, :challenger, :root_privatekey, :user_key_dir end

    @db = "/ctf/scoreboard/db/scoreboard.sqlite3"
    @challenger = "challenger"
    @root_privatekey = "/home/atdog/admin_script/id_rsa"
    @user_key_dir = "/home/atdog/admin_script/user_keys/"
end

#!/usr/bin/env ruby

require "./mylib/Workstation"
require "digest"
require 'securerandom'
require 'sqlite3'

if __FILE__ == $0
    db = "/ctf/scoreboard/db/scoreboard.sqlite3"
    fail "Database not exist - #{db}" if not File.exist? db
    db = SQLite3::Database.new( db )

    round = 1

    host = "10.113.208.209"

    sha256 = Digest::SHA256.new
    msg = SecureRandom.hex(1024)
    digest = sha256.digest msg
    token = digest.unpack("H*")[0]

    service_user = "service1"
    service_flag_dir = "/home/user/flags/#{service_user}/"

    w = Workstation.new(host, "root", "./id_rsa")
    # check user exist
    puts "Check user exist"
    w.exec_remote("id user")
    # create folder
    puts "Create flag directory"
    w.exec_remote("mkdir -p #{service_flag_dir}")
    w.exec_remote("chown #{service_user}:#{service_user} #{service_flag_dir}")
    w.exec_remote("chmod 700 #{service_flag_dir}")
    # set new flag
    puts "Place new flag"
    w.exec_remote("echo #{token} > #{service_flag_dir}/flag")
    w.exec_remote("chown #{service_user}:#{service_user} #{service_flag_dir}/flag")
    w.exec_remote("chmod 600 #{service_flag_dir}/flag")
    # write db
    puts "Write into database"
    rows = db.execute( "insert into FLAG (value, team_id, service_id, round) values ('#{token}',1,1,#{round})" )

end

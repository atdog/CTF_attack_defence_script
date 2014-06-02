#!/usr/bin/env ruby

require "./mylib/Workstation"
require "digest"
require 'securerandom'
require 'sqlite3'
require 'thread/pool'

if __FILE__ == $0
    db = "/ctf/scoreboard/db/scoreboard.sqlite3"
    fail "Database not exist - #{db}" if not File.exist? db
    db = SQLite3::Database.new( db )

    sha256 = Digest::SHA256.new

    round = 1

    pool = Thread.pool(10)

    team = {
        'ip' => '10.113.208.209',
        'team_id' => '1',
        'service_id' => '1',
        'service_user' => 'service1',
    }

    pool.process team do |arg|
        #      arg = team
        host = arg['ip']
        team_id = arg['team_id']
        service_id = arg['service_id']
        service_user = arg['service_user']

        msg = SecureRandom.hex(1024)
        digest = sha256.digest msg
        token = digest.unpack("H*")[0]

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
        rows = db.execute( "insert into FLAG (value, team_id, service_id, round) values ('#{token}',#{team_id},#{service_id},#{round})" )

    end
    pool.shutdown
end

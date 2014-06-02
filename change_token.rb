#!/usr/bin/env ruby

require "./mylib/Workstation"
require "./mylib/DB"
require "./mylib/Token"
require "./AdminConfig"
require 'thread/pool'

if __FILE__ == $0
    challenger = AdminConfig.challenger

    db = DB.new(AdminConfig.db)

    flag = Token.new()

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

        token = flag.gen

        service_flag_dir = "/home/#{challenger}/flags/#{service_user}/"

        w = Workstation.new(host, "root", AdminConfig.root_privatekey)
        # check user exist
        puts "Check user #{challenger} exist"
        w.exec_remote("id #{challenger}")
        # create folder
        puts "Create flag directory"
        w.exec_remote("mkdir -p #{service_flag_dir}")
        w.exec_remote("chown #{service_user}:#{service_user} #{service_flag_dir}")
        w.exec_remote("chmod 700 #{service_flag_dir}")
        # set owner
        w.exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/flags")
        # set new flag
        puts "Place new flag"
        w.exec_remote("echo #{token} > #{service_flag_dir}/flag")
        w.exec_remote("chown #{service_user}:#{service_user} #{service_flag_dir}/flag")
        w.exec_remote("chmod 600 #{service_flag_dir}/flag")
        # write db
        puts "Write into database"
        db.insert_flag(token, team_id, service_id, round)

    end

    pool.shutdown
end

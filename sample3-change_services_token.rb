#!/usr/bin/env ruby
#
require_relative 'lib/CTF'
require_relative 'lib/AdminConfig'
require 'open3'
require 'thread/pool'

if __FILE__ == $0
    if ARGV.size != 3
        puts "#{$0} ctf_id max_round 1"
        puts "#{$0} ctf_id max_round round"
        exit
    end
    ctf_id = ARGV[0]
    max_round = ARGV[1].to_i
    round = ARGV[2].to_i

    if round <= max_round
        ctf = CTF.new ctf_id

        pool = Thread.pool(10)
        ctf.each_team do |team|
            pool.process team do |arg|
                puts "[+] Find workstation for #{arg['name']}. IP: #{arg['ip']}"
                puts "[+] Max: #{max_round} Round: #{round}"
                arg["workstation"].change_services_token round
            end
        end
        pool.shutdown
        # set next round

        db = SQLite3::Database.open( AdminConfig.db )

        begin
            services = db.execute("update ctfs set round = :round where id = :ctfid", "round" => round ,"ctfid" => ctf_id)
        rescue
            fail "Query services error"
        end

        o, s = Open3.capture2("cd /ctf/scoreboard/ && /home/atdog/.rvm/rubies/ruby-2.1.2/bin/rake scoring:current")
        fail "Failed to rake scoring:current" if not s.success?
        puts o

        # new at
        round += 1
        o, s = Open3.capture2("at now + 5 min", :stdin_data => "/home/atdog/.rvm/rubies/ruby-2.1.2/bin/ruby /home/atdog/admin_script/sample3-change_services_token.rb #{ctf_id} #{max_round} #{round} >> /home/atdog/admin_script/change_token.log 2>&1 ")
        puts o
    else
        puts "Close CTF"
    end
end

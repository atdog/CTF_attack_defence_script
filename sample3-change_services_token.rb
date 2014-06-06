#!/usr/bin/env ruby
#
require_relative 'lib/CTF'
require 'open3'

if __FILE__ == $0
    if ARGV.size != 3
        puts "#{$0} ctf_id max_round 1"
        puts "#{$0} ctf_id max_round round"
        exit
    end
    ctf_id = ARGV[0]
    max_round = ARGV[1]
    round = ARGV[2]

    if round <= max_round
        ctf = CTF.new ctf_id
        ctf.each_team do |team|
            puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
            w = team["workstation"]
            puts "[+] Max: #{max_round} Round: #{round}"
            w.change_services_token round
            # set next round
            round += 1
            o, s = Open3.capture2("at now + 5 min", :stdin_data => "/home/atdog/.rvm/rubies/ruby-2.1.2/bin/ruby /home/atdog/admin_script/sample3-change_services_token.rb #{ctf_id} #{max_round} #{round} >> /home/atdog/admin_script/change_token.log")
            puts o
        end
    else
        puts "Close CTF"
    end
end

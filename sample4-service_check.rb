#!/usr/bin/env ruby
#
require_relative 'lib/CTF'
require 'timeout'
require 'thread/pool'

if __FILE__ == $0
    if ARGV.size != 2
        puts "#{$0} ctf_id round"
        exit
    end

    round = ARGV[1].to_i
    ctf = CTF.new ARGV[0]
    ctf.each_team do |team|
        begin
            Timeout.timeout(5) do 
                puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
                w = team["workstation"]
                puts "Round: #{round}"
                w.check_services_status round
            end
        rescue
            puts "Check Timeout"
        end
    end
end

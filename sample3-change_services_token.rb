#!/usr/bin/env ruby
#
require_relative 'lib/CTF'

if __FILE__ == $0
    if ARGV.size != 2
        puts "#{$0} ctf_id round"
        exit
    end
    ctf = CTF.new ARGV[0]
    ctf.each_team do |team|
        puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
        w = team["workstation"]
        puts "[+] Round: #{ARGV[1]}"
        w.change_services_token ARGV[1]
    end
end

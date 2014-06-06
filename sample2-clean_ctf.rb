#!/usr/bin/env ruby
#
require_relative 'lib/CTF'

if __FILE__ == $0
    ctf = CTF.new 1
    ctf.each_team do |team|
        puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
        w = team["workstation"]

        w.cleanup
    end
end
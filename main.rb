#!/usr/bin/env ruby
#
require_relative 'lib/CTF'

if __FILE__ == $0
    ctf = CTF.new
    ctf.each_team do |team|
        puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
        w = team["workstation"]
        p w.services
#          w.cleanup
#          w.create_user
#          w.generate_ssh_keypair
#          w.setup_sudoers
#          w.create_service_user
#  
#          w.deploy_services
#          w.change_token
    end
end

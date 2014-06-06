#!/usr/bin/env ruby
#
require_relative 'lib/CTF'

if __FILE__ == $0
    ctf = CTF.new 1
    ctf.each_team do |team|
        puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
        w = team["workstation"]

        w.cleanup
        w.create_user
        w.generate_ssh_keypair
        w.setup_sudoers

        w.deploy_services
        w.change_services_token

        w.check_services_status
    end
end

#!/usr/bin/env ruby
#
require_relative 'lib/CTF'

if __FILE__ == $0
    if ARGV.size != 1
        puts "#{$0} ctf_id"
        exit
    end

    ctf = CTF.new ARGV[0]
    ctf.each_team do |team|
        puts "[+] Create workstation for #{team['name']}. IP: #{team['ip']}"
        w = team["workstation"]

        w.cleanup
        w.create_user
        w.generate_ssh_keypair
        w.setup_sudoers

        w.deploy_services
        # change token
#          w.change_services_token
        # check status
#          w.check_services_status
    end
end

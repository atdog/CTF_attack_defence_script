#!/usr/bin/env ruby
#
require "./mylib/Workstation"
require "./AdminConfig"

if __FILE__ == $0
    host = "10.113.208.209"
    service_id = 1
    service_name = "service1"
    challenger = AdminConfig.challenger

    w = Workstation.new(host, "root", AdminConfig.root_privatekey)
    puts "Check user #{challenger} exist"
    w.exec_remote("id #{challenger}")

    puts "Deploy service - #{service_name}"
    w.copy_to_remote("./services/#{service_id}/#{service_name}")
    w.exec_remote("mkdir -p /home/#{challenger}/services/#{service_name}")
    w.exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/services")
    w.exec_remote("chown #{service_name}:#{service_name} /home/#{challenger}/services/#{service_name}")
    w.exec_remote("mv #{service_name} /home/#{challenger}/services/#{service_name}/service")
    w.exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/services/#{service_name}/service")
end

#!/usr/bin/env ruby
#
require "./mylib/Workstation"
require "./AdminConfig"

if __FILE__ == $0
    host = "10.113.208.209"
    service_id = 1
    service_name = "service1"
    service_port = 999
    challenger = AdminConfig.challenger

    w = Workstation.new(host, "root", AdminConfig.root_privatekey)
    puts "Check user #{challenger} exist"
    w.exec_remote("id #{challenger}")

    puts "Cleanup /etc/services"
    w.exec_remote("sed -E '/#{service_name}\\s+#{service_port}/d' -i /etc/services")
    w.exec_remote("rm -f /etc/xinetd.d/#{service_name}")
    w.exec_remote("rm -r /home/#{challenger}/services/#{service_name}")

    puts "Deploy service - #{service_name}"
    w.copy_to_remote("./services/#{service_id}/#{service_name}")
    w.exec_remote("mkdir -p /home/#{challenger}/services/#{service_name}")
    w.exec_remote("mv #{service_name} /home/#{challenger}/services/#{service_name}/service")
    w.exec_remote("chown -R root:#{challenger} /home/#{challenger}/services")
    w.exec_remote("chmod 771 /home/#{challenger}/services/#{service_name}/service")
    
    puts "Setup xinetd"
    w.copy_to_remote("./services/#{service_id}/#{service_name}_xinetd")
    w.exec_remote("mv #{service_name}_xinetd /etc/xinetd.d")

    puts "Write /etc/services"
    w.exec_remote("echo '#{service_name}        #{service_port}/tcp' >> /etc/services")

    puts "Starting service ... "
    puts w.exec_remote("service xinetd restart")
    puts "Done"
end

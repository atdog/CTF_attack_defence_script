class Service
    def initialize(w, id, name, port, check_script)
        @w = w
        @id = id
        @name = name
        @port = port
        @check_script = check_script
    end

    def deploy
        service_id = @id
        service_name = @name
        service_port = @port
        challenger = AdminConfig.challenger

        puts "Check user #{challenger} exist"
        @w.exec_remote("id #{challenger}")

        create_service_user

        puts "Cleanup /etc/services"
        @w.exec_remote("sed -E '/#{service_name}\\s+#{service_port}/d' -i /etc/services")

        puts "Deploy service - #{service_name}"
        @w.copy_to_remote("./services/#{service_id}/#{service_name}")
        @w.exec_remote("mkdir -p /home/#{challenger}/services/#{service_name}")
        @w.exec_remote("mv #{service_name} /home/#{challenger}/services/#{service_name}/service")
        @w.exec_remote("chown -R root:#{challenger} /home/#{challenger}/services")
        @w.exec_remote("chmod 771 /home/#{challenger}/services/#{service_name}/service")

        puts "Setup xinetd"
        @w.copy_to_remote("./services/#{service_id}/#{service_name}_xinetd")
        @w.exec_remote("mv #{service_name}_xinetd /etc/xinetd.d")

        puts "Write /etc/services"
        @w.exec_remote("echo '#{service_name}        #{service_port}/tcp' >> /etc/services")

        puts "Starting service ... "
        puts @w.exec_remote("service xinetd restart")
    end

    def create_service_user
        puts "Create service user: #{@name}"
        @w.exec_remote("useradd #{@name}")
    end
end

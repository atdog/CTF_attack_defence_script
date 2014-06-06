require_relative "Token"
require "open3"

class Service
    def initialize(w, id, name, port, check_script)
        @w = w
        @id = id
        @name = name
        @port = port
        @check_script = check_script
        @challenger = AdminConfig.challenger
    end

    def deploy
        service_id = @id
        service_name = @name
        service_port = @port

        puts "Check user #{@challenger} exist"
        @w.exec_remote("id #{@challenger}")

        create_service_user

        puts "Cleanup /etc/services"
        @w.exec_remote("sed -E '/#{service_name}\\s+#{service_port}/d' -i /etc/services")

        puts "Deploy service - #{service_name}"
        @w.copy_to_remote("./services/#{service_id}/#{service_name}")
        @w.exec_remote("mkdir -p /home/#{@challenger}/services/#{service_name}")
        @w.exec_remote("mv #{service_name} /home/#{@challenger}/services/#{service_name}/service")
        @w.exec_remote("chown -R root:#{@challenger} /home/#{@challenger}/services")
        @w.exec_remote("chmod 771 /home/#{@challenger}/services/#{service_name}/service")

        puts "Setup xinetd"
        @w.copy_to_remote("#{AdminConfig.services_dir}/#{service_id}/#{service_name}_xinetd")
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

    def change_token(round)
        team_id = @w.team_id
        service_id = @id
        service_user = @name

        token = Token.new()
        service_token = token.gen

        service_flag_dir = "/home/#{@challenger}/flags/#{service_user}/"

        # check user exist
        puts "Check user #{@challenger} exist"
        @w.exec_remote("id #{@challenger}")
        # create folder
        puts "Create flag directory"
        @w.exec_remote("mkdir -p #{service_flag_dir}")
        @w.exec_remote("chown root:#{service_user} #{service_flag_dir}")
        @w.exec_remote("chmod 750 #{service_flag_dir}")
        # set owner
        @w.exec_remote("chown #{@challenger}:#{@challenger} /home/#{@challenger}/flags")
        # set new flag
        puts "Place new flag - #{service_token}"
        @w.exec_remote("echo #{service_token} > #{service_flag_dir}/flag")
        @w.exec_remote("chown root:#{service_user} #{service_flag_dir}/flag")
        @w.exec_remote("chmod 440 #{service_flag_dir}/flag")
        # write db
        token.insert(service_token, team_id, service_id, round)
    end

    def portscan(round = 1)
        team_id = @w.team_id
        STDOUT.write "PortScan ##{@port} on #{@w.host} - "
        o, s = Open3.capture2("nmap -Pn -p #{@port} #{@w.host}")

        fail o if not s.success?
        if o =~ /#{@port}\/tcp open/n
            puts "open"
            db = SQLite3::Database.open(AdminConfig.db)

            begin
                db.execute( "insert into service_states (team_id, service_id, state, round, log) values (:team_id, :service_id, :state, :round, :log)",
                           "team_id" => team_id,
                           "service_id" => @id,
                           "state" => 0,
                           "round" => round,
                           "log" => o)
            rescue
                fail "insert service_states error" 
            end
            return true
        end
        puts "close"
        db = SQLite3::Database.open(AdminConfig.db)

        begin
            db.execute( "insert into service_states (team_id, service_id, state, round, log) values (:team_id, :service_id, :state, :round, :log)",
                       "team_id" => team_id,
                       "service_id" => @id,
                       "state" => 1,
                       "round" => round,
                       "log" => o)
        rescue
            fail "insert service_states error" 
        end
        return false
    end
end

require_relative "AdminConfig"
require_relative "Token"
require "open3"

class Workstation
    attr_accessor :services

    def initialize(host, user = "root", private_key = AdminConfig.root_privatekey)
        fail "Private key is missing." if not File.exist?(private_key)
        @host = host
        @user = user 
        @private_key = private_key
        init_services
    end

    def init_services
        db = AdminConfig.db
        fail "Database not exist - #{db}" if not File.exist? db
        @db = SQLite3::Database.open( db )

        begin
            services = @db.execute("select * from services")
        rescue
            fail "Query teams error" 
        end

        @services = []
        services.each do |service|
            @services.push({ "id" => service[0], "name" => service[2], "port" => service[3] })
        end
    end

    def exec(cmd)
        o, s = Open3.capture2(cmd)
        puts "[!] CMD: #{cmd}" if not s.success?
        return o, s
    end

    def exec_remote(cmd)
        o, s = exec("ssh -i #{@private_key} #{@user}@#{@host} \"#{cmd}\" ")
        fail "Failed to exec cmd on remote server - #{@host}" if not s.success?
        o
    end

    def exec_local(cmd)
        o, s = exec(cmd)
        fail "Failed to exec cmd on local " if not s.success?
        o
    end

    def copy_to_remote(file)
        o, s = exec("scp -i #{@private_key} #{file} #{@user}@#{@host}:~")
        fail "Failed to copy file to remote sever - #{@host} " if not s.success?
        o
    end

    def create_user(challenger = AdminConfig.challenger)
        puts "Create user: #{challenger}"
        exec_remote("useradd -m #{challenger}")
    end

    def generate_ssh_keypair(challenger = AdminConfig.challenger, directory = AdminConfig.user_key_dir)
        puts "Generate SSH RSA key-pair"
        user_key = "#{challenger}@#{@host}"
        user_passphrase = ""
        exec_local("ssh-keygen -t rsa -b 2048 -f #{directory}/#{user_key} -N '#{user_passphrase}'")

        puts "Copy public key to server - #{@host} "
        copy_to_remote("#{directory}/#{user_key}.pub")

        puts "Move pulic key to authorized_keys for user"
        exec_remote("mkdir /home/#{challenger}/.ssh")
        exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/.ssh")
        exec_remote("chmod 700 /home/#{challenger}/.ssh")
        exec_remote("mv '#{user_key}.pub' /home/#{challenger}/.ssh/authorized_keys")
        exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/.ssh/authorized_keys")
        exec_remote("chmod 644 /home/#{challenger}/.ssh/authorized_keys")
    end

    def cleanup(challenger = AdminConfig.challenger)
        begin
            exec_remote("id #{challenger}")

            puts "Remove user from sudoers"
            exec_remote("sed -E '/#{challenger}\\sALL/d' -i /etc/sudoers")
            exec_remote("sed -E '/Cmnd_Alias XINETD/d' -i /etc/sudoers")

            puts "Remove user: #{challenger}"
            exec_remote("rm -rf /home/#{challenger}")
            exec_remote("deluser --remove-all-files #{challenger} 2>/dev/null")
            exec_local("rm -f #{AdminConfig.user_key_dir}/#{challenger}@#{@host}*")

            service_name = "service1"
            puts "Remove user: #{service_name}"
            exec_remote("id #{service_name}")
            exec_remote("deluser --remove-all-files #{service_name} 2>/dev/null")

            puts "Remove service"
            exec_remote("rm -f /etc/xinetd.d/*")
            puts exec_remote("service xinetd restart")
        rescue
        end
    end

    def setup_sudoers(challenger = AdminConfig.challenger)
        puts "Setup sudoers to let user restart xinetd as root"
        exec_remote("echo 'Cmnd_Alias XINETD = /usr/sbin/service xinetd restart' >> /etc/sudoers")
        exec_remote("echo '#{challenger} ALL=(root) NOPASSWD: XINETD' >> /etc/sudoers")
    end

    def create_service_user
        puts "Create service user: service1"
        exec_remote("useradd service1")
    end

    def deploy_services
        service_id = 1
        service_name = "service1"
        service_port = 999
        challenger = AdminConfig.challenger

        puts "Check user #{challenger} exist"
        exec_remote("id #{challenger}")

        puts "Cleanup /etc/services"
        exec_remote("sed -E '/#{service_name}\\s+#{service_port}/d' -i /etc/services")

        puts "Deploy service - #{service_name}"
        copy_to_remote("./services/#{service_id}/#{service_name}")
        exec_remote("mkdir -p /home/#{challenger}/services/#{service_name}")
        exec_remote("mv #{service_name} /home/#{challenger}/services/#{service_name}/service")
        exec_remote("chown -R root:#{challenger} /home/#{challenger}/services")
        exec_remote("chmod 771 /home/#{challenger}/services/#{service_name}/service")

        puts "Setup xinetd"
        copy_to_remote("./services/#{service_id}/#{service_name}_xinetd")
        exec_remote("mv #{service_name}_xinetd /etc/xinetd.d")

        puts "Write /etc/services"
        exec_remote("echo '#{service_name}        #{service_port}/tcp' >> /etc/services")

        puts "Starting service ... "
        puts exec_remote("service xinetd restart")
    end

    def change_token(round = 1)
        challenger = AdminConfig.challenger
        team_id = 1
        service_id = 1
        service_user = "service1"

        token = Token.new()
        service_token = token.gen

        service_flag_dir = "/home/#{challenger}/flags/#{service_user}/"

        # check user exist
        puts "Check user #{challenger} exist"
        exec_remote("id #{challenger}")
        # create folder
        puts "Create flag directory"
        exec_remote("mkdir -p #{service_flag_dir}")
        exec_remote("chown root:#{service_user} #{service_flag_dir}")
        exec_remote("chmod 750 #{service_flag_dir}")
        # set owner
        exec_remote("chown #{challenger}:#{challenger} /home/#{challenger}/flags")
        # set new flag
        puts "Place new flag"
        exec_remote("echo #{service_token} > #{service_flag_dir}/flag")
        exec_remote("chown root:#{service_user} #{service_flag_dir}/flag")
        exec_remote("chmod 440 #{service_flag_dir}/flag")
        # write db
        token.insert(service_token, team_id, service_id, round)
    end

    private :init_services

end

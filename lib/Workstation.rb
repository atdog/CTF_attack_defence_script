require_relative "AdminConfig"
require_relative "Service"
require "open3"
require "thread/pool"

class Workstation
    attr_accessor :services, :team_id, :host

    def initialize(ctfid, team_id, host, user = "root", private_key = AdminConfig.root_privatekey, challenger = AdminConfig.challenger)
        fail "Private key is missing." if not File.exist?(private_key)
        @ctfid = ctfid
        @team_id = team_id
        @host = host
        @user = user 
        @private_key = private_key
        @challenger = challenger
        init_services
    end

    def init_services
        db = AdminConfig.db
        fail "Database not exist - #{db}" if not File.exist? db
        db = SQLite3::Database.open( db )

        begin
            services = db.execute("select * from services where ctf_id = :ctfid", "ctfid" => @ctfid)
        rescue
            fail "Query services error" 
        end

        @services = []
        services.each do |service|
            @services.push(Service.new(self, service[0], service[2], service[3], service[4]))
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

    def create_user
        puts "Create user: #{@challenger}"
        exec_remote("useradd -m #{@challenger}")
    end

    def generate_ssh_keypair(directory = AdminConfig.user_key_dir)
        puts "Generate SSH RSA key-pair"
        user_key = "#{@challenger}@#{@host}.pem"
        user_passphrase = ""
        exec_local("ssh-keygen -t rsa -b 2048 -f #{directory}/#{user_key} -N '#{user_passphrase}'")
        exec_local("curl -F \"private_key=@#{directory}/#{user_key}\" -F \"id=#{@team_id}\" localhost:3000/team/upload_private_key")

        puts "Copy public key to server - #{@host} "
        copy_to_remote("#{directory}/#{user_key}.pub")

        puts "Move pulic key to authorized_keys for user"
        exec_remote("mkdir /home/#{@challenger}/.ssh")
        exec_remote("chown #{@challenger}:#{@challenger} /home/#{@challenger}/.ssh")
        exec_remote("chmod 700 /home/#{@challenger}/.ssh")
        exec_remote("mv '#{user_key}.pub' /home/#{@challenger}/.ssh/authorized_keys")
        exec_remote("chown #{@challenger}:#{@challenger} /home/#{@challenger}/.ssh/authorized_keys")
        exec_remote("chmod 644 /home/#{@challenger}/.ssh/authorized_keys")
    end

    def cleanup
        begin
            exec_remote("id #{@challenger}")

            puts "Remove user from sudoers"
            exec_remote("sed -E '/#{@challenger}\\sALL/d' -i /etc/sudoers")
            exec_remote("sed -E '/Cmnd_Alias XINETD/d' -i /etc/sudoers")

            puts "Remove user: #{@challenger}"
            exec_remote("rm -rf /home/#{@challenger}")
            exec_remote("deluser --remove-all-files #{@challenger} 2>/dev/null")
            exec_local("rm -f #{AdminConfig.user_key_dir}/#{@challenger}@#{@host}*")

            @services.each do |service|
                service_name = service.name
                puts "Remove user: #{service_name}"
                exec_remote("id #{service_name}")
                exec_remote("deluser --remove-all-files #{service_name} 2>/dev/null")
            end

            puts "Remove service"
            exec_remote("rm -f /etc/xinetd.d/*")
            puts exec_remote("service xinetd restart")
        rescue
        end
    end

    def setup_sudoers
        puts "Setup sudoers to let user restart xinetd as root"
        exec_remote("echo 'Cmnd_Alias XINETD = /usr/sbin/service xinetd restart' >> /etc/sudoers")
        exec_remote("echo '#{@challenger} ALL=(root) NOPASSWD: XINETD' >> /etc/sudoers")
    end

    def deploy_services
        @services.each do |service|
            service.deploy
        end
    end

    def change_services_token(round = 1)
        pool = Thread.pool(8)
        @services.each do |service|
            pool.process do
                service.change_token round
            end
        end
        pool.shutdown
    end

    def check_services_status(round = 1)
        pool = Thread.pool(8)
        @services.each do |service|
            pool.process do
                service.portscan round
            end
        end
        pool.shutdown
    end

    private :init_services

end

require 'beaker/hypervisor/aws_sdk'
require 'digest'

module Beaker
  class F5 < Beaker::AwsSdk
    # Provision all hosts on EC2 using the AWS::EC2 API
    #
    # @return [void]
    def provision
      start_time = Time.now

      # Perform the main launch work
      launch_all_nodes()

      # Wait for each node's status checks to be :ok, otherwise the F5
      # application (mcpd) may not be started yet
      wait_for_status_checks("ok")

      # Add metadata tags to each instance
      add_tags()

      # Grab the ip addresses and dns from EC2 for each instance to use for ssh
      populate_dns()

      #enable root if user is not root
      enable_root_on_hosts()

      # This is done by the Beaker AWS hypervisor but isn't valid for F5
      # Set the hostname for each box
      # set_hostnames()

      # This is done by the Beaker AWS hypervisor but isn't valid for F5
      # Configure /etc/hosts on each host
      # configure_hosts()

      @logger.notify("aws-sdk: Provisioning complete in #{Time.now - start_time} seconds")

      nil #void
    end
    
    # Waits until all boxes' status checks reach the desired state
    #
    # @param status [String] EC2 state to wait for, "ok" "initializing" etc.
    # @return [void]
    # @api private
    def wait_for_status_checks(status)
      @logger.notify("f5: Now wait for all hosts' status checks to reach state #{status}")
      @hosts.each do |host|
        instance = host['instance']
        name = host.name

        @logger.notify("f5: Wait for status check #{status} for node #{name}")

        # TODO: should probably be a in a shared method somewhere
        for tries in 1..10
          begin
            if instance.client.describe_instance_status({:instance_ids => [instance.id]})[:instance_status_set].first[:system_status][:status] == status
              # Always sleep, so the next command won't cause a throttle
              backoff_sleep(tries)
              break
            elsif tries == 10
              raise "Instance never reached state #{status}"
            end
          rescue AWS::EC2::Errors::InvalidInstanceID::NotFound => e
            @logger.debug("Instance #{name} not yet available (#{e})")
          end
          backoff_sleep(tries)
        end
      end
    end

    # If we don't define this method then the default will be used, which
    # logs into the host and twiddles the /etc/sshd_config and otherwise
    # isn't applicable to f5
    def configure
    end

    # Enables root access for a host when username is not root
    #
    # @return [void]
    # @api private
    def enable_root_f5(host)
      for tries in 1..10
        begin
          #This command is problematic as the F5 is not always done loading
          if host.exec(Command.new("modify sys db systemauth.disablerootlogin value false"), :acceptable_exit_codes => [0,1]).exit_code == 0 \
            and host.exec(Command.new("modify sys global-settings gui-setup disabled"), :acceptable_exit_codes => [0,1]).exit_code == 0 \
            and host.exec(Command.new("save sys config"), :acceptable_exit_codes => [0,1]).exit_code == 0
            backoff_sleep(tries)
            break
          elsif tries == 10
            raise "Instance was unable to be configured"
          end
        rescue Beaker::Host::CommandFailure => e
          @logger.debug("Instance not yet configured (#{e})")
        end
        backoff_sleep(tries)
      end
      host['user'] = 'root'
      host.close
      sha256 = Digest::SHA256.new
      password = sha256.hexdigest((1..50).map{(rand(86)+40).chr}.join.gsub(/\\/,'\&\&'))
      host.exec(Command.new("echo -e '#{password}\\n#{password}' | tmsh modify auth password admin"))
      host['ssh'][:password] = password
      @logger.notify("f5: Configured admin password to be #{password}")
      host.close
    end

    # Retrieve the public key locally from the executing users ~/.ssh directory
    #
    # @return [String] contents of public key
    # @api private
    def public_key
      user_specified_key = Array(options[:ssh][:keys]).first + '.pub'
      filename = File.expand_path(user_specified_key)
      unless File.exists? filename
        filename = File.expand_path('~/.ssh/id_rsa.pub')
        unless File.exists? filename
          filename = File.expand_path('~/.ssh/id_dsa.pub')
          unless File.exists? filename
            raise RuntimeError, "Expected one of #{user_specified_key}, " +
              "~/.ssh/id_rsa.pub, or ~/.ssh/id_dsa.pub but found none"
          end
        end
      end

      add_private_key(filename)
      @logger.debug "aws-sdk: Found local public key"
      File.read(filename)
    end

    # Retrieves the private key locally from the executing users ~/.ssh directory
    # and adds it to the local SSH Agent
    #
    # @return [String] filepath
    def add_private_key(pub_key="~/.ssh/id_rsa.pub")
      private_key, ext = pub_key.split('.pub', -1)
      filename = File.expand_path(private_key)
      if File.exists? filename
        @logger.debug "aws-sdk: Adding SSH Private Key to SSH Agent"
        system "/usr/bin/ssh-add #{filename}"
      end
    end
  end
end

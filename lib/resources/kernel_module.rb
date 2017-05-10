# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter
# author: Aaron Lippold
# license: All rights reserved

module Inspec::Resources
  class KernelModule < Inspec.resource(1)
    name 'kernel_module'
    desc 'Use the kernel_module InSpec audit resource to test kernel modules on Linux platforms. These parameters are located under /lib/modules. Any submodule may be tested using this resource.'
    example "
      describe kernel_module('bridge') do
        it { should be_loaded }
        it { should_not be_disabled }
        it { should_not be_blacklisted }
      end

      describe kernel_module('sstfb') do
        it { should_not be_loaded }
        it { should be_disabled }
        it { should be_disabled_via_bin_false }
      end

      describe kernel_module('nvidiafb') do
        it { should_not be_loaded }
        it { should be_disabled }
        it { should be_disabled_via_bin_true }
      end

      describe kernel_module('floppy') do
        it { should be_blacklisted }
        it { should_not be_enabled }
      end

      describe kernel_module('floppy') do
        it { should be_blacklisted }
        it { should_not be_enabled }
      end

      describe kernel_module('video') do
        it { should_not be_blacklisted }
        it { should be_enabled }
      end
    "

    def initialize(modulename = nil)
      @module = modulename
      # this resource is only supported on Linux
      return skip_resource 'The `kernel_parameter` resource is not supported on your OS.' if !inspec.os.linux?
    end

    def loaded?
      if inspec.os.redhat? || inspec.os.name == 'fedora'
        lsmod_cmd = '/sbin/lsmod'
      else
        lsmod_cmd = 'lsmod'
      end

      # get list of all modules
      cmd = inspec.command(lsmod_cmd)
      return false if cmd.exit_status != 0

      # check if module is loaded
      re = Regexp.new('^'+Regexp.quote(@module)+'\s')
      found = cmd.stdout.match(re)
      !found.nil?
    end

    # @note maintain logcal agreement with 'disabled?' method
    alias enabled? loaded?

    def blacklisted?
      if inspec.os.redhat? || inspec.os.name == 'fedora'
        modprobe_cmd = "/sbin/modprobe --showconfig | grep blacklist | grep #{@module}"
      else
        modprobe_cmd = "modprobe --showconfig | grep blacklist | grep #{@module}"
      end
      cmd = inspec.command(modprobe_cmd)
      cmd.exit_status.zero? ? cmd.stdout.delete("\n") : nil
    end

    # @todo add a 'kernel.modules_disabled' check as well from grub.conf
    def disabled?
      if inspec.os.redhat? || inspec.os.name == 'fedora'
        modprobe_cmd = "/sbin/modprobe --showconfig | grep \"^install\" | grep \"/bin\" | grep -E \"(true|false)\" | grep #{@module}"
      else
        modprobe_cmd = "modprobe --showconfig | grep \"^install\" | grep \"/bin\" | grep -E \"(true|false)\" | grep #{@module}"
      end
      cmd = inspec.command(modprobe_cmd)
      cmd.exit_status.zero? ? cmd.stdout.delete("\n") : nil
    end

    def disabled_via_bin_true?
      if inspec.os.redhat? || inspec.os.name == 'fedora'
        modprobe_cmd = "/sbin/modprobe --showconfig | grep \"^install\" | grep \"/bin\" | grep \"true\" | grep #{@module}"
      else
        modprobe_cmd = "modprobe --showconfig | grep \"^install\" | grep \"/bin\" | grep \"true\" | grep #{@module}"
      end
      cmd = inspec.command(modprobe_cmd)
      cmd.exit_status.zero? ? cmd.stdout.delete("\n") : nil
    end

    def disabled_via_bin_false?
      if inspec.os.redhat? || inspec.os.name == 'fedora'
        modprobe_cmd = "/sbin/modprobe --showconfig | grep \"^install\" | grep \"/bin\" | grep \"false\" | grep #{@module}"
      else
        modprobe_cmd = "modprobe --showconfig | grep \"^install\" | grep \"/bin\" | grep \"false\" | grep #{@module}"
      end
      cmd = inspec.command(modprobe_cmd)
      cmd.exit_status.zero? ? cmd.stdout.delete("\n") : nil
    end

    def version
      if inspec.os.redhat? || inspec.os.name == 'fedora'
        modinfo_cmd = "/sbin/modinfo -F version #{@module}"
      else
        modinfo_cmd = "modinfo -F version #{@module}"
      end
      cmd = inspec.command(modinfo_cmd)
      cmd.exit_status.zero? ? cmd.stdout.delete("\n") : nil
    end

    def to_s
      "Kernel Module #{@module}"
    end
  end
end

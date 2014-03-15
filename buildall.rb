#: coding utf-8

#
# for NetBSD
#

require 'mail'
require 'pit'
require 'pp'

def setup()

  ENV['CVSROOT'] = "anoncvs@anoncvs.NetBSD.org:/cvsroot"
  ENV['CVS_RSH'] = "ssh"

  config = Pit.get("netbsd build", :require => {
    :mail_from    => "from@example.jp",
    :mail_to      => "to@example.jp",
    :mail_subject => "NetBSD build.sh result",
    :mail_address => "smtp.example.jp",
    :mail_port    => 25,
    :mail_domain  => "example.jp",
    :mail_username => "USERNAME",
    :mail_password => "PASSWORD",
    :mail_auth      => "plain",
    :mail_starttls  => true
  } )
  
  return config
end

def runcmd(cmd)
  pid = Process.spawn(cmd)
  Signal.trap(:INT) {
    Process.kill('KILL', pid)
    exit(0)
  }
  Process.wait()
end

def checkout()
  dir = '/usr'
  Dir.chdir(dir) {
    cmd = "wget ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-current/tar_files/src.tar.gz"
    runcmd(cmd)
    cmd = "tar xzf src.tar.gz"
    runcmd(cmd)
  }
end

def update()
  dir = '/usr/src'
  Dir.chdir(dir) {
    cmd = "cvs update -dP"
    runcmd(cmd)
  }
end

def get_source()
  if Dir.exist?('/usr/src/CVS') == true
    update()
  else
    checkout()
  end
end

def get_all_arch(arch_readme)
  :ST_DELIM1
  :ST_DELIM2

  st = :ST_DELIM1
  archs ||= []
  
  lines = File.open(arch_readme).readlines()
  lines.each {|line|
    case st
    when :ST_DELIM1
      if line =~ /\A\Z/
        st = :ST_DELIM2
      end
      
    when :ST_DELIM2
      if line =~ /\A\Z/
        break
      else
        sp = line.split()
        archs << sp[0]
      end
    end
  }
  return archs
end

def do_build(machine_arch)
  src_dir = '/usr/src'
  result_file = "#{src_dir}/#{machine_arch}.build.result"
  Dir.chdir(src_dir) {|path|
    cmd = "./build.sh -m #{machine_arch} build | tee #{result_file} 2>&1"
    runcmd(cmd)
  }
  return result_file
end

def result_sccess?(result_file)
  result = File.open(result_file).read()
  
  if result.include?('*** BUILD ABORTED ***')
    return false
  end
  return true
end

def build_message(arch, success)
  res = ''
  if success == true
    res = "success"
  else
    res = "failure"
  end
  message = sprintf("%-16s %s", arch, res)
  return message
end

def send_mail(config, message)
  # Todo password を pit 化
  options = {
    :address              => config[:mail_address],
    :port                 => config[:mail_port],
    :domain               => config[:mail_domain],
    :user_name            => config[:mail_username],
#    :password             => config[:mail_password],
    :password             => 'PASSWORD',
    :authentication       => config[:mail_auth],
    :enable_starttls_auto => config[:mail_starttls],
  }

  Mail.defaults do
    delivery_method :smtp, options
  end

  mail = Mail.new
  mail.from = config[:mail_from]
  mail.to = config[:mail_to]
  mail.subject = config[:mail_subject]
  mail.charset ='iso-2022-jp'
  mail.add_content_transfer_encoding
  mail.body  = message
  mail.deliver

end

def main(argv)
  arch_readme = '/usr/src/sys/arch/README'
  machine_arch = get_all_arch(arch_readme)
  message = ''
  config = setup()

  get_source()

  machine_arch.each {|arch|
    result_file = do_build(arch)
    ok = result_sccess?(result_file)
    ok = true
    message << build_message(arch, ok)
    message << "\n"
  }
  send_mail(config, message)
end

main(ARGV)

#: coding utf-8

#
# for NetBSD
#

require 'mail'

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
    cmd = "./build.sh -m #{machine_arch} build >#{result_file} 2>&1"
    system(cmd)
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
  message = ''
  if success == true
    message = "#{arch} success"
  else
    message = "#{arch} failure"
  end
  return message
end

def send_mail(message)
  options = {
    :address              => "smtp.example.jp",
    :port                 => 25,
    :domain               => 'example.jp',
    :user_name            => 'USERNAME',
    :password             => 'PASSWORD',
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }

  Mail.defaults do
    delivery_method :smtp, options
  end

  mail = Mail.new
  mail.from = 'from@example.jp'
  mail.to = 'to@example.jp'
  mail.subject = 'NetBSD build.sh result'
  mail.charset ='iso-2022-jp'
  mail.add_content_transfer_encoding
  mail.body  = message
  mail.deliver
end

def main(argv)
  arch_readme = '/usr/src/sys/arch/README'
  machine_arch = get_all_arch(arch_readme)
  
  machine_arch.each {|arch|
    result_file = do_build(arch)
    ok = result_sccess?(result_file)
    message = build_message(arch, ok)
    send_mail(message)
  }
end

main(ARGV)

# coding: utf-8

def setenv()
  ENV['CVSROOT'] = "anoncvs@anoncvs.NetBSD.org:/cvsroot"
  ENV['CVS_RSH'] = "ssh"
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

def main(argv)
  setenv()
  get_source()
end

main(ARGV)


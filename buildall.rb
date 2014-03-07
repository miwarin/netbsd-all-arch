#: coding utf-8

#
# for NetBSD
#
# buildall.rb /usr/src/sys/arch/README
#

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

def main(argv)
  arch_readme = argv[0]
  archs = get_all_arch(arch_readme)
  puts archs
end

main(ARGV)

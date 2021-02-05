#!/usr/bin/env ruby
script_root = File.expand_path("#{File.dirname(__FILE__)}")
$LOAD_PATH << "#{script_root}/hosts_maker"
require 'maker'

hostfile = ARGV[0]
hosts_maker = VagrantHosts::Maker.new(configuration_root: script_root, host_file: hostfile)
(hosts,groups) = hosts_maker.get_hosts_and_groups

if(ARGV.include?('hosts'))
  puts JSON.pretty_generate(hosts)
elsif(ARGV.include?('groups'))
  puts groups.to_yaml
else
  puts "USAGE: #{File.basename($0)} HOSTFILE [hosts|groups]"
  puts "  hosts  : dumps out the host maker generated host list in json"
  puts "  groups : dumps out the host maker generated groups in yaml"
end
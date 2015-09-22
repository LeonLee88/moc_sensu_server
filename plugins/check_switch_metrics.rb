#!/usr/bin/env ruby
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'snmp'

class SNMPIfStats < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         short: '-h host',
         boolean: true,
         default: '127.0.0.1',
         required: true

  option :community,
         short: '-C snmp community',
         boolean: true,
         default: 'public'
  def run
    ifTable_columns = ["ifDescr", "ifInOctets", "ifOutOctets", "ifSpeed","ifOperStatus"]
    SNMP::Manager.open(:host => "#{config[:host]}", :community => "#{config[:community]}") do |manager|
    
    start_stats = manager.walk(ifTable_columns)
    manager.walk(ifTable_columns) do |row|
        row.each { |vb| print "\t#{vb.value}" }
        puts
    end
    
  end
  ok
  end
end

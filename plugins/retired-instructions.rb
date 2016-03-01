#! /usr/bin/env ruby
require 'sensu-plugin/metric/cli'
require 'socket'

#
# CPU Graphite
#
class CpuGraphite < Sensu::Plugin::Metric::CLI::Graphite

  def run
    begin
      `sudo perf stat -e instructions -a sleep 1 2>temp_out.txt`
      temp_out = File.open('temp_out.txt','r').read
      instructions = temp_out.split("\n\n")[1].scan(/\d/i).join.to_i
      `rm temp_out.txt`
      output instructions
      exit 0
    rescue StandardError => error
      output error
      exit 2
    end
  end

end

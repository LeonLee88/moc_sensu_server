#!/usr/bin/env ruby

require 'rubygems'
require 'sensu-handler'

class SensuToInfluxDB < Sensu::Handler
  def filter; end

  def handle
    influxdb_server = settings['influxdb']['host']
    influxdb_port   = settings['influxdb']['port']
    influxdb_user   = settings['influxdb']['username']
    influxdb_pass   = settings['influxdb']['password']
    influxdb_db     = settings['influxdb']['database']

    mydata = []
    check_name = @event['check']['name']
    if check_name.include? "-"
        check_name = check_name.gsub!'-','_'
    end
    series = check_name
    @event['check']['output'].each_line do |metric|
      m = metric.split
      puts m
      next unless m.count == 3
      host = m[0].split('.', 3)[0]
      tag = m[0].split('.', 3)[2]
      next unless host
      value = m[1].to_f
      mydata = { host: @event['client']['name'], value: value,
                 ip: @event['client']['address']
               }
      
      timestamp = m[2].to_f*1000
      #puts "http://#{influxdb_server}:#{influxdb_port}/write?db=#{influxdb_db}' --data-binary '#{series},host=#{host},metric=#{tag}  value=#{value} #{timestamp}"
      `curl -X POST -d '[{"name":"#{series}","columns":["time","host","metric","value"],"points":[[#{timestamp},"#{host}","#{tag}",#{value}]]}]' 'http://#{influxdb_server}:#{influxdb_port}/db/#{influxdb_db}/series?u=#{influxdb_user}&p=#{influxdb_pass}&time_precision=ms'`
      #`curl -i -XPOST 'http://#{influxdb_server}:#{influxdb_port}/write?db=#{influxdb_db}' --data-binary '#{series},host=#{host},metric=#{tag}  value=#{value} #{timestamp}'`
    end
  end
end

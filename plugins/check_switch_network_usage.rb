#!/usr/bin/env ruby
# http://www.cisco.com/c/en/us/support/docs/ip/simple-network-management-protocol-snmp/8141-calculate-bandwidth-snmp.html
#
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'snmp'
require 'time'

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

  option :ishighspeed,
         description: 'default value is false, if the link speed is greater than 1 gigabits/s, please use true',
         short: '-i ishighspeed',
         boolean: true,
         default: false

  def run

    switchName = getSystemName

    ifTable_first_poll_cols = ["ifDescr", "ifInOctets", "ifOutOctets"]
    ifTable_sec_poll_cols = ["ifDescr", "ifInOctets", "ifOutOctets", "ifOperStatus", config[:ishighspeed] ? "ifHighSpeed":"ifSpeed"]

    octets_start = {}
    SNMP::Manager.open(:host => "#{config[:host]}", :community => "#{config[:community]}") do |manager|
    	start_timer = Time.now.to_i
    	#Mark the time of starting polling
	#First polling start
    	manager.walk(ifTable_first_poll_cols) do |row|
        	key = [switchName,row[0].value.downcase,"ifInSpeed"].join(".")
        	octets_start[key] = row[1].value
        	
        	key = [switchName,row[0].value.downcase,"ifOutSpeed"].join(".")
        	octets_start[key] = row[2].value
    	end
     
    	#sleep 6 secs
    	poll_interval = 6
    	sleep(poll_interval)
    	
        #Second polling start
    	speed_metrics = {}
    	manager.walk(ifTable_sec_poll_cols) do |row|

		# Put channel/vlan/interface status
                status_key = [switchName,row[0].value.downcase,"ifStatus"].join(".")
		speed_metrics[status_key] = row[3].value

                # SNMP ifHighSpeed is current bandwidth in units of 100000 bits/s, ifSpeed is of 1 bit/s
                bandwidth = (config[:ishighspeed] ? row[4].value.to_i*1000000 : row[4].value.to_i)
                bandwidth_key = [switchName,row[0].value.downcase,"bandwidth"].join(".")
                speed_metrics[bandwidth_key] = bandwidth

		# Put channel/vlan/interface inbound speed
        	speed_key = [switchName,row[0].value.downcase,"ifInSpeed"].join(".")
                utilization_key = [switchName,row[0].value.downcase,"ifInUtilization"].join(".")
                #puts "test",row[1].value.to_f, octets_start[key].to_f
                ifInSpeed = (row[1].value.to_i - octets_start[speed_key].to_i)*8 / poll_interval
        	
                speed_metrics[speed_key] = ifInSpeed

                speed_metrics[utilization_key] = ifInSpeed*100/ bandwidth

		# Put channel/vlan/interface outbound speed
	        speed_key = [switchName,row[0].value.downcase,"ifOutSpeed"].join(".")
                utilization_key = [switchName,row[0].value.downcase,"ifOutUtilization"].join(".")
                ifOutSpeed = (row[2].value.to_i - octets_start[speed_key].to_i)*8 / poll_interval

        	speed_metrics[speed_key] = ifOutSpeed
                
                speed_metrics[utilization_key] = ifOutSpeed*100/ bandwidth
    	end

        speed_metrics.each do |key,value|
          puts "#{key}\t#{value}\t#{start_timer+poll_interval}"
        end
    end
    ok
  end
  
  def getObject(oName)
      SNMP::Manager.open(:host => "#{config[:host]}", :community => "#{config[:community]}") do |manager|
         response = manager.get(oName)
         response.each_varbind do |vb|
            return  vb.value.to_s
         end
       end
  end

  def getSystemName
      sysName = getObject("sysName.0")
      formatName(sysName)
  end

  def formatName(nameStr)
      values = nameStr.downcase
      #values.join('.')
  end

end

#!/usr/bin/env ruby

require 'rubygems'
require 'json'

##Get the list of series
templist=[]
series = `curl -G 'http://localhost:8086/db/sensu_db/series?u=root&p=root' --data-urlencode "q=list series"`
series = JSON.parse(series)
newseries=series[0]["points"]
 newseries.each do |item|
	next if item[1]=="cluster_metrics"
	templist.push(item[1])
end

puts templist

## Getting data from influxdb and calculate for the whole cluster
total = `curl -G 'http://localhost:8086/db/sensu_db/series?u=root&p=root' --data-urlencode "q=select sum(value) from memory_metrics where time >now() - 5m and metric = 'rc.fas.harvard.edu.memory.total'"`
used = `curl -G 'http://localhost:8086/db/sensu_db/series?u=root&p=root' --data-urlencode "q=select sum(value) from memory_metrics where time >now() - 5m and metric = 'rc.fas.harvard.edu.memory.used'"`

totalnum = JSON.parse(total)[0]["points"][0][1]
usednum = JSON.parse(used)[0]["points"][0][1]
used_percentage = ((usednum/totalnum).to_f*100).round(2)

puts totalnum
puts usednum
puts used_percentage
t = Time.now.to_i
#a.sub!'0',t
postdata = `curl -X POST -d '[{"name":"cluster_metrics","columns":["time","metric","used","total","used_percentage"],"points":[[#{t},"memory_metrics",#{usednum},#{totalnum},#{used_percentage}]]}]' 'http://localhost:8086/db/sensu_db/series?u=root&p=root'`


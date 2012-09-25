require "redis"

redis_conf = IO.read "/etc/redis/redis.conf"


port = /port.(\d+)/.match(redis_conf)[1]

# Uncomment to have rails start a redis server
#`redis-server #{redis_conf}`
#res = `ps aux | grep redis-server`

#unless res.include?("redis-server") && res.include?(redis_conf)
#  raise "Couldn't start redis"
#end

REDIS = Redis.new(:port => port)
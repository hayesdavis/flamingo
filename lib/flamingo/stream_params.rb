module Flamingo
  #
  # Facade for redis:
  # database object that behaves like a hash
  #
  class StreamParams
    include Enumerable
    attr_accessor :stream_name

    def initialize(stream_name)
      self.stream_name = stream_name
    end

    def set(key,*values)
      delete(key)
      add(key,*values)
    end

    def []=(key,values)
      values = [values] unless values.is_a?(Array)
      set(key,*values)
    end

    def add(key,*values)
      values.each do |value|
        Flamingo.redis.sadd redis_key(key), value
      end
    end

    def remove(key,*values)
      values.each do |value|
        Flamingo.redis.srem redis_key(key), value
      end
    end

    def delete(key)
      Flamingo.redis.del redis_key(key)
    end

    def get(key)
      Flamingo.redis.smembers redis_key(key)
    end
    alias_method :[], :get

    def keys
      Flamingo.redis.keys(redis_key_pattern).map do |key|
        key.split("?")[1].to_sym
      end
    end

    def all
      keys.inject({}) do |h,key|
        h[key] = get(key)
        h
      end
    end

    def each
      keys.each do |key|
        yield(key,get(key))
      end
    end

    private
      def redis_key_pattern
        "streams/#{stream_name}?*"
      end

      def redis_key(key)
        "streams/#{stream_name}?#{key}"
      end
  end
end

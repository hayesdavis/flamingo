module Flamingo
  module Dispatcher
    class Map
      
      class << self
        def define(&block)
          block.call(instance)
        end
        
        def instance
          @instance ||= Map.new
        end
      end
      
      def initialize
        @routes = {}
        @route_count = 0
      end
      
      def method_missing(name,*args)
        route(name,*args)
      end
      
      def respond_to?(name)
        true
      end
      
      def route(type,options)
        queue = options.delete(:queue)
        routes = (@routes[type] ||= [])
        if options.empty?
          routes << Flamingo::Dispatcher::Route.new(queue,nil,nil)
        else
          options.each do |field,value|
            routes << Flamingo::Dispatcher::Route.new(queue,field,value)
          end
        end
      end
      
      def destinations(type,event)
        dests = []
        type_routes = routes_for(type) + routes_for(:all)
        type_routes.each do |route|
          if route.match?(event)
            dests << route.destination
          end
        end
        dests.uniq
      end
      
      private
        def routes_for(type)
          @routes[type] ||= []
        end
      
    end
  end
end
module Flamingo
  module Daemon
    module TrapKeeper
      
      # Use instead of Kernel.trap to ensure that only the process that 
      # originally registered the trap has its block executed. This is necessary 
      # for cases where we fork after setting up traps since the child process 
      # gets the traps from the parent.
      def trap(signal,&block)
        owner_pid = Process.pid
        Kernel.trap(signal) do
          if Process.pid == owner_pid
            block.call
          end
        end
      end
      
      module_function :trap
      
    end
  end
end
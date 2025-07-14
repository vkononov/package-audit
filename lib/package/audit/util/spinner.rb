module Package
  module Audit
    module Util
      class Spinner
        ANIMATION_SPEED = 0.1
        STATES = %w[| / - \\]

        def initialize(message = 'Loading...')
          @message = message
          @running = false
          @thread = nil
        end

        def start # rubocop:disable Metrics/MethodLength
          return if ENV['RACK_ENV'] == 'test'
          raise 'Loading indicator already started.' if @running

          @running = true
          @thread = Thread.new do
            step = 0
            while @running
              if @running && ENV['RUBY_ENV'] != 'test' && ENV['RACK_ENV'] != 'test'
                print "\r#{@message} #{STATES[step % STATES.length]}"
              end
              sleep ANIMATION_SPEED
              step += 1
            end
          end
        end

        def stop
          return if ENV['RACK_ENV'] == 'test'
          return unless @running

          @running = false
          @thread&.join
          clear_console_line
        end

        private

        def clear_console_line
          print "\r#{' ' * (@message.length + 2)}\r"
        end
      end
    end
  end
end

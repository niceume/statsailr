require "forwardable"

module StatSailr
  module Output
    class OutputMessage
      extend Forwardable
      def_delegators :@parent, :capture

      attr :type
      attr :content, true

      def initialize(type, content, parent)
        @type = type
        @content = content
        @parent = parent
      end

      def set_content( content )
        @content = content
      end

      def to_s
        return @content.to_s
      end

      def run(stream)
        raise ArgumentError, 'missing block' unless block_given?
        if capture == false
          begin 
            yield
          rescue => e
            raise e
          end
        else
          orig_stream = stream.dup
          IO.pipe do |r, w|
            # system call dup2() replaces the file descriptor 
            stream.reopen(w) 
            # there must be only one write end of the pipe;
            # otherwise the read end does not get an EOF 
            # by the final `reopen`
            w.close  # Now 'stream=$stdout' and 'r' are paired. orig_stream points to original stream(STDOUT).
            t = Thread.new { r.read }
            begin
              yield
            rescue => e
              raise e
            ensure
              stream.reopen orig_stream # restore file descriptor
              @content << t.value # join and get the result of the thread
            end
          end
        end
      end
    end

    class OutputNode
      extend Forwardable
      def_delegators :@parent, :capture

      attr :tag, :parent, :messages
      def initialize(tag , parent)
        @tag = tag
        @children = []
        @parent = parent
        @messages = []
      end

      def new_node(tag)
        @children << OutputNode.new(tag, self)
        return @children.last
      end

      def new_message( type, content )
        @messages << OutputMessage.new(type, content, self )
        return @messages.last
      end

      def each_node(&blk)
        @children.each(&blk)
      end

      def each_message(&blk)
        @messages.each(&blk)
      end

      def to_s()
        str = ""
        if ! @messages.empty?
          each_message(){|message|
            str << message.to_s()
          }
        end
        if ! @children.empty?
          each_node(){|node|
            str << node.to_s()
          }
        end
        return str
      end
    end

    class OutputManager
      attr :root_node, :current_node, :capture
      alias_method :parent, :capture

      def initialize( capture: true )
        @root_node = OutputNode.new("root", self)
        @current_node = @root_node
        @capture = capture
      end

      def reset
        @root_node = OutputNode.new("root", self)
        @current_node = @root_node
        return self
      end

      def move_to_new_node(tag)
        @current_node = @current_node.new_node(tag)
        return @current_node
      end

      def recurse_move_to_new_node(tag , *tags)
        @current_node = @current_node.new_node(tag)
        if ! tags.nil?
          tags.each(){|child_tag|
            @current_node = @current_node.new_node(child_tag)
          }
        end
        return @current_node
      end

      def add_new_message( type, content: "" )
        message = @current_node.new_message(type, content)
        return message
      end

      def move_to_root()
        @current_node = @root_node
      end

      def move_up()
        @current_node = @current_node.parent
      end

      def move_down()
        if @current_node.children.size >= 1
          @current_node = @current_node.children.last
        else
          return nil
        end
      end

      def to_s()
        @root_node.to_s()
      end
    end
  end
end


# require_relative "./output_manager.rb"
#
# mngr = StatSailr::Output::OutputManager.new(capture: true) # Level0 (root)
#
# mngr.move_to_new_node("BLOCK_TO_R")  # Level1
# mngr.recurse_move_to_new_node(["PROC","PRINT"], "head")  # Level2 and 3
# mngr.add_new_message(:text).run($stdout){
#   puts "Hello"
#   puts "World"
# }
#
# p mngr.current_node.messages[0].content
# p mngr.current_node.tag
#
# mngr.move_up
# p mngr.current_node.tag
#
# mngr.move_up
# p mngr.current_node.tag
#
# p "root_node"
# p mngr.root_node.tag


# Copyright 2019 DragonRuby LLC
# MIT License
# console.rb has been released under MIT (*only this file*).

# Contributors outside of DragonRuby who also hold Copyright:
# - Kevin Fischer: https://github.com/kfischer-okarin

module GTK
  class Console
    attr_accessor :show_reason, :log, :logo, :background_color,
                  :text_color, :animation_duration,
                  :max_log_lines, :max_history, :log,
                  :last_command_errored, :last_command, :error_color, :shown_at,
                  :header_color, :archived_log, :last_log_lines, :last_log_lines_count,
                  :suppress_left_arrow_behavior, :command_set_at,
                  :toast_ids,
                  :font_style

    def initialize
      @font_style = FontStyle.new(font: 'font.ttf', size_enum: -1, line_height: 1.1)
      @disabled = false
      @log_offset = 0
      @visible = false
      @toast_ids = []
      @archived_log = []
      @log = [ 'Console ready.' ]
      @max_log_lines = 1000  # I guess...?
      @max_history = 1000  # I guess...?
      @command_history = []
      @command_history_index = -1
      @nonhistory_input = ''
      @logo = 'console-logo.png'
      @history_fname = 'console_history.txt'
      @background_color = Color.new [0, 0, 0, 224]
      @text_color = Color.new [255, 255, 255]
      @error_color = Color.new [200, 50, 50]
      @header_color = Color.new [100, 200, 220]
      @animation_duration = 1.seconds
      @shown_at = -1
      load_history
    end

    def console_text_width
      @console_text_width ||= ($gtk.logical_width - 20).idiv(font_style.letter_size.x)
    end

    def save_history
      $gtk.ffi_file.storefile(@history_fname, @command_history.reverse.join("\n"))
    end

    def load_history
      @command_history.clear
      str = $gtk.ffi_file.loadfile(@history_fname)
      return if str.nil?  # no history to load.

      str.chomp!("\n")  # Don't let endlines at the end cause extra blank line.
      str.chomp!("\r")
      str.each_line { |s|
        s.chomp!("\n")
        s.chomp!("\r")
        if s.length > 0
          @command_history.unshift s
          break if @command_history.length >= @max_history
        end
      }

      @command_history.uniq!
    end

    def disable
      @disabled = true
    end

    def enable
      @disabled = false
    end

    def addsprite obj
      obj[:id] ||= "id_#{obj[:path]}_#{Time.now.to_i}".to_sym

      if @last_line_log_index &&
         @last_sprite_line.is_a?(Hash) &&
         @last_sprite_line[:id] == obj[:id]

        @log[@last_line_log_index] = obj
        return
      end

      @log << obj
      @last_line_log_index = @log.length - 1
      @last_sprite_line = obj
      nil
    end

    def add_primitive obj
      if obj.is_a? Hash
        addsprite obj
      else
        addtext obj
      end
      nil
    end

    def addtext obj
      @last_log_lines_count ||= 1

      str = obj.to_s

      log_lines = []

      str.each_line do |s|
        s.wrapped_lines(self.console_text_width).each do |l|
          log_lines << l
        end
      end

      if log_lines == @last_log_lines
        @last_log_lines_count += 1
        new_log_line_with_count = @last_log_lines.last + " (#{@last_log_lines_count})"
        if log_lines.length > 1
          @log = @log[0..-(@log.length - log_lines.length)] + log_lines[0..-2] + [new_log_line_with_count]
        else
          @log = @log[0..-2] + [new_log_line_with_count]
        end
        return
      end

      log_lines.each do |l|
        @log.shift if @log.length > @max_log_lines
        @log << l
      end

      @last_log_lines_count = 1
      @last_log_lines = log_lines
      nil
    end

    def ready?
      visible? && @toggled_at.elapsed?(@animation_duration, Kernel.global_tick_count)
    end

    def hidden?
      !@visible
    end

    def visible?
      @visible
    end

    # @gtk
    def show reason = nil
      @shown_at = Kernel.global_tick_count
      @show_reason = reason
      toggle if hidden?
    end

    # @gtk
    def hide
      if visible?
        toggle
        @archived_log += @log
        if @archived_log.length > @max_log_lines
          @archived_log = @archived_log.drop(@archived_log.length - @max_log_lines)
        end
        @log.clear
        @show_reason = nil
        clear_toast
      end
    end

    def close
      hide
    end

    def clear_toast
      @toasted_at = nil
      @toast_duration = 0
    end

    def toggle
      @visible = !@visible
      @toggled_at = Kernel.global_tick_count
    end

    def currently_toasting?
      return false if hidden?
      return false unless @show_reason == :toast
      return false unless @toasted_at
      return false if @toasted_at.elapsed?(5.seconds, Kernel.global_tick_count)
      return true
    end

    def toast_extended id = nil, duration = nil, *messages
      if !id.is_a?(Symbol)
        raise <<-S
* ERROR:
args.gtk.console.toast has the following signature:

  def toast id, *messages
  end

The id property uniquely defines the message and must be
a symbol.

After that, you can provide all the objects you want to
look at.

Example:

  args.gtk.console.toast :say_hello,
                            \"Hello world.\",
                            args.state.tick_count

Toast messages autohide after 5 seconds.

If you need to look at something for longer, use
args.gtk.console.perma_toast instead (which you can manually dismiss).

S
      end

      return if currently_toasting?
      return if @toast_ids.include? id
      @toasted_at = Kernel.global_tick_count
      log_once_info :perma_toast_tip, "Use console.perma_toast to show the toast for longer."
      dwim_duration = 5.seconds
      addtext "* toast :#{id}"
      puts "* TOAST: :#{id}"
      messages.each do |message|
        lines = message.to_s.wrapped_lines(self.console_text_width)
        dwim_duration += lines.length.seconds
        addtext "** #{message}"
        puts "** #{message}"
      end
      show :toast
      @toast_duration += duration || dwim_duration
      @toast_ids << id
      set_command "$gtk.console.hide"
    end

    def perma_toast id = nil, messages
      toast_extended id, 600.seconds, *messages
    end

    def toast id = nil, *messages
      toast_extended id, nil, *messages
    end

    def console_toggle_keys
      [
        :backtick!,
        :tilde!,
        :superscript_two!,
        :section_sign!,
        :ordinal_indicator!,
        :circumflex!,
      ]
    end

    def console_toggle_key_down? args
      args.inputs.keyboard.key_down.any? console_toggle_keys
    end

    def eval_the_set_command
      cmd = current_input_str.strip
      if cmd.length != 0
        @log_offset = 0
        prompt.clear

        @command_history.pop while @command_history.length >= @max_history
        @command_history.unshift cmd
        @command_history_index = -1
        @nonhistory_input = ''

        if cmd == 'quit' || cmd == ':wq' || cmd == ':q!' || cmd == ':q' || cmd == ':wqa'
          $gtk.request_quit
        else
          puts "-> #{cmd}"
          begin
            @last_command = cmd
            Kernel.eval("$results = (#{cmd})")
            if $results.nil?
              puts "=> nil"
            elsif $results == :console_silent_eval
            else
              puts "=> #{$results}"
            end
            @last_command_errored = false
          rescue Exception => e
            string_e = "#{e}"
            @last_command_errored = true
            if (string_e.include? "wrong number of arguments")
              method_name = (string_e.split ":")[0].gsub "'", ""
              results = Kernel.docs_search method_name
              if !results.include "* DOCS: No results found."
                puts results
                log results
              end
            end

            puts "#{e}"
            log "#{e}"
          end
        end
      end
    end

    def inputs_scroll_up_full? args
      return false if @disabled
      args.inputs.keyboard.key_down.pageup ||
        (args.inputs.keyboard.key_up.b && args.inputs.keyboard.key_up.control)
    end

    def scroll_up_full
      @log_offset += lines_on_one_page
      @log_offset = @log.size if @log_offset > @log.size
    end

    def inputs_scroll_up_half? args
      return false if @disabled
      args.inputs.keyboard.ctrl_u
    end

    def scroll_up_half
      @log_offset += lines_on_one_page.idiv(2)
      @log_offset = @log.size if @log_offset > @log.size
    end

    def inputs_scroll_down_full? args
      return false if @disabled
      args.inputs.keyboard.key_down.pagedown ||
        (args.inputs.keyboard.key_up.f && args.inputs.keyboard.key_up.control)
    end

    def scroll_down_full
      @log_offset -= lines_on_one_page
      @log_offset = 0 if @log_offset < 0
    end

    def inputs_scroll_down_half? args
      return false if @disabled
      args.inputs.keyboard.ctrl_d
    end

    def inputs_clear_command? args
      return false if @disabled
      args.inputs.keyboard.escape || args.inputs.keyboard.ctrl_g
    end

    def scroll_down_half
      @log_offset -= lines_on_one_page.idiv(2)
      @log_offset = 0 if @log_offset < 0
    end

    def mouse_wheel_scroll args
      @inertia ||= 0

      if args.inputs.mouse.wheel && args.inputs.mouse.wheel.y > 0
        @inertia = 1
      elsif args.inputs.mouse.wheel && args.inputs.mouse.wheel.y < 0
        @inertia = -1
      end

      if args.inputs.mouse.click
        @inertia = 0
      end

      return if @inertia == 0

      if @inertia != 0
        @inertia = (@inertia * 0.7)
        if @inertia > 0
          @log_offset -= 1
        elsif @inertia < 0
          @log_offset += 1
        end
      end

      if @inertia.abs < 0.01
        @inertia = 0
      end

      if @log_offset > @log.size
        @log_offset = @log.size
      elsif @log_offset < 0
        @log_offset = 0
      end
    end

    def process_inputs args
      if console_toggle_key_down? args
        args.inputs.text.clear
        toggle
      end

      return unless visible?

      args.inputs.text.each { |str| prompt << str }
      args.inputs.text.clear
      mouse_wheel_scroll args

      @log_offset = 0 if @log_offset < 0

      if args.inputs.keyboard.key_down.enter
        eval_the_set_command
      elsif args.inputs.keyboard.key_down.v
        if args.inputs.keyboard.key_down.control || args.inputs.keyboard.key_down.meta
          prompt << $gtk.ffi_misc.getclipboard
        end
      elsif args.inputs.keyboard.key_down.up
        if @command_history_index == -1
          @nonhistory_input = current_input_str
        end
        if @command_history_index < (@command_history.length - 1)
          @command_history_index += 1
          self.current_input_str = @command_history[@command_history_index].dup
        end
      elsif args.inputs.keyboard.key_down.down
        if @command_history_index == 0
          @command_history_index = -1
          self.current_input_str = @nonhistory_input
          @nonhistory_input = ''
        elsif @command_history_index > 0
          @command_history_index -= 1
          self.current_input_str = @command_history[@command_history_index].dup
        end
      elsif inputs_scroll_up_full? args
        scroll_up_full
      elsif inputs_scroll_down_full? args
        scroll_down_full
      elsif inputs_scroll_up_half? args
        scroll_up_half
      elsif inputs_scroll_down_half? args
        scroll_down_half
      elsif inputs_clear_command? args
        prompt.clear
        @command_history_index = -1
        @nonhistory_input = ''
      elsif args.inputs.keyboard.key_down.backspace || args.inputs.keyboard.key_down.delete
        prompt.backspace
      elsif args.inputs.keyboard.key_down.tab
        prompt.autocomplete
      end

      args.inputs.keyboard.key_down.clear
      args.inputs.keyboard.key_up.clear
      args.inputs.keyboard.key_held.clear
    end

    def write_primitive_and_return_offset(args, left, y, str, archived: false)
      if str.is_a?(Hash)
        padding = 10
        args.outputs.reserved << [left + 10, y - padding * 1.66, str[:w], str[:h], str[:path]].sprite
        return str[:h] + padding
      else
        write_line args, left, y, str, archived: archived
        return line_height_px
      end
    end

    def write_line(args, left, y, str, archived: false)
      color = color_for_log_entry(str)
      color = color.mult_alpha(0.5) if archived

      args.outputs.reserved << font_style.label(x: left.shift_right(10), y: y, text: str, color: color)
    end

    def render args
      return if !@toggled_at

      if visible?
        percent = @toggled_at.global_ease(@animation_duration, :flip, :quint, :flip)
      else
        percent = @toggled_at.global_ease(@animation_duration, :flip, :quint)
      end

      return if percent == 0

      bottom = top - (h * percent)
      args.outputs.reserved << [left, bottom, w, h, *@background_color.mult_alpha(percent)].solid
      args.outputs.reserved << [right.shift_left(110), bottom.shift_up(630), 100, 100, @logo, 0, (80.0 * percent).to_i].sprite

      y = bottom + 2  # just give us a little padding at the bottom.
      prompt.render args, x: left.shift_right(10), y: y
      y += line_height_px * 1.5
      args.outputs.reserved << line(y: y, color: @text_color.mult_alpha(percent))
      y += line_height_px.to_f / 2.0

      ((@log.size - @log_offset) - 1).downto(0) do |idx|
        offset_after_write = write_primitive_and_return_offset args, left, y, @log[idx]
        y += offset_after_write
        break if y > top
      end

      # past log seperator
      args.outputs.reserved << line(y: y + line_height_px.half, color: @text_color.mult_alpha(0.25 * percent))

      y += line_height_px

      ((@archived_log.size - @log_offset) - 1).downto(0) do |idx|
        offset_after_write = write_primitive_and_return_offset args, left, y, @archived_log[idx], archived: true
        y += offset_after_write
        break if y > top
      end

      render_log_offset args
      render_help args, top if percent == 1
    end

    def render_help args, top
      [
        "* Prompt Commands:                   ",
        "You can type any of the following    ",
        "commands in the command prompt.      ",
        "** docs: Provides API docs.          ",
        "** $gtk: Accesses the global runtime.",
        "* Shortcut Keys:                     ",
        "** full page up:   ctrl + b          ",
        "** full page down: ctrl + f          ",
        "** half page up:   ctrl + u          ",
        "** half page down: ctrl + d          ",
        "** clear prompt:   ctrl + g          ",
        "** up arrow:       next command      ",
        "** down arrow:     prev command      ",
      ].each_with_index do |s, i|
        args.outputs.reserved << [args.grid.right - 10,
                                  top - 100 - line_height_px * i * 0.8,
                                  s, -3, 2, 180, 180, 180].label
      end
    end

    def render_log_offset args
      return if @log_offset <= 0
      args.outputs.reserved << font_style.label(
        x: right.shift_left(5),
        y: top.shift_down(5 + line_height_px),
        text: "[#{@log_offset}/#{@log.size}]",
        color: @text_color,
        alignment_enum: 2
      )
    end

    def include_error_marker? text
      include_any_words?(text.gsub('OutputsDeprecated', ''), error_markers)
    end

    def error_markers
      ["exception", "error", "undefined method", "failed", "syntax", "deprecated"]
    end

    def include_subdued_markers? text
      include_any_words? text, subdued_markers
    end

    def include_any_words? text, words
      words.any? { |w| text.downcase.include?(w) && !text.downcase.include?(":#{w}") }
    end

    def subdued_markers
      ["reloaded", "exported the"]
    end

    def calc args
      if visible? &&
         @show_reason == :toast &&
         @toasted_at &&
         @toasted_at.elapsed?(@toast_duration, Kernel.global_tick_count)
        hide
      end

      if !$gtk.paused? && visible? && (show_reason == :exception || show_reason == :exception_on_load)
        hide
      end

      if $gtk.files_reloaded.length > 0
        clear_toast
        @toast_ids.clear
      end
    end

    def tick args
      begin
        return if @disabled
        render args
        calc args
        process_inputs args
      rescue Exception => e
        @disabled = true
        $stdout.puts e
        $stdout.puts "* FATAL: The GTK::Console console threw an unhandled exception and has been reset. You should report this exception (along with reproduction steps) to DragonRuby."
      end
    end

    def set_command_with_history_silent command, histories, show_reason = nil
      set_command_extended command: command, histories: histories, show_reason: show_reason
    end

    def defaults_set_command_extended
      {
        command: "puts 'Hello World'",
        histories: [],
        show_reason: nil,
        force: false
      }
    end

    def set_command_extended opts
      opts = defaults_set_command_extended.merge opts
      @command_history.concat opts[:histories]
      @command_history << opts[:command]  if @command_history[-1] != opts[:command]
      self.current_input_str = opts[:command] if @command_set_at != Kernel.global_tick_count || opts[:force]
      @command_set_at = Kernel.global_tick_count
      @command_history_index = -1
      save_history
    end

    def set_command_with_history command, histories, show_reason = nil
      set_command_with_history_silent command, histories, show_reason
      show show_reason
    end

    # @gtk
    def set_command command, show_reason = nil
      set_command_silent command, show_reason
      show show_reason
    end

    def set_command_silent command, show_reason = nil
      set_command_with_history_silent command, [], show_reason
    end

    def set_system_command command, show_reason = nil
      if $gtk.platform == "Mac OS X"
        set_command_silent "$gtk.system \"open #{command}\""
      else
        set_command_silent "$gtk.system \"start #{command}\""
      end
    end

    def system_command
      if $gtk.platform == "Mac OS X"
        "open"
      else
        "start"
      end
    end

    private

    def w
      $gtk.logical_width
    end

    def h
      $gtk.logical_height
    end

    # methods top; left; right
    # Forward to grid
    %i[top left right].each do |method|
      define_method method do
        $gtk.args.grid.send(method)
      end
    end

    def line_height_px
      font_style.line_height_px
    end

    def lines_on_one_page
      (h - 4).idiv(line_height_px)
    end

    def line(y:, color:)
      [left, y, right, y, *color].line
    end

    def include_row_marker? log_entry
      log_entry[0] == "|"
    end

    def include_header_marker? log_entry
      return false if log_entry.include? "NOTIFY:"
      return false if log_entry.include? "INFO:"
      return true if log_entry.include? "DOCS:"
      (log_entry.start_with? "* ")   ||
      (log_entry.start_with? "** ")  ||
      (log_entry.start_with? "*** ")
    end

    def color_for_log_entry(log_entry)
      if include_row_marker? log_entry
        @text_color
      elsif include_error_marker? log_entry
        @error_color
      elsif include_subdued_markers? log_entry
        @text_color.mult_alpha(0.5)
      elsif include_header_marker? log_entry
        @header_color
      elsif log_entry.start_with?("====") || log_entry.include?("app") && !log_entry.include?("apple")
        @header_color
      else
        @text_color
      end
    end

    def prompt
      @prompt ||= Prompt.new(font_style: font_style, text_color: @text_color, console_text_width: console_text_width)
    end

    def current_input_str
      prompt.current_input_str
    end

    def current_input_str=(str)
      prompt.current_input_str = str
    end

    def clear
      @archived_log.clear
      @log.clear
      @prompt.clear
      :console_silent_eval
    end
  end
end
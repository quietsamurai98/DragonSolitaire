# INSTRUCTIONS
# Select all the text in this google doc (yes all of it) and paste it into "app/community_help.rb". Then require it at the top of "main.rb". Yes. All the text in this file is valid Ruby code lol.



# You can invoke community help on any object by calling .community_help on that object. For example: $gtk.community_help.
# Optionally you can provide search terms (separated with spaces) to filter the help: 
# $gtk.community_help "term-one term-two"

# If you'd like to contribute help, but don't want (or don't have time to) make the help interactive, 
# put help text (and requests for help) in the CONTRIBUTING HELP AS JUST TEXT section below.
# Someone else will come by and code it up.



# CONTRIBUTING HELP AS JUST TEXT
# The help text below cannot be found interactively via the community_help function.

=begin Write stuff inside of and try to format it as best you can.
Write your help text in here (between the =begin and =end)

















=end





# BEGIN REQUIRED STUFF. SKIP THIS AREA
# DON'T CHANGE ANYTHING IN THIS SECTION UNLESS YOU KNOW WHAT YOU'RE DOING
module CommunityHelp
  def self.included klass
    @__community_help_classes__ ||= []
    @__community_help_classes__ << klass
    @__community_help_classes__.uniq!
  end
end

$community_help = CommunityHelp
# END REQUIRED STUFF. OKAY COOL YOU ARE PASSED THE DANGER ZONE


# CONTRIBUTING INTERACTIVE HELP. WELCOME!
# Everything below this line is related to interactive help. If you find the instructions intimidating
# just add your help text to the CONTRIBUTING HELP AS JUST TEXT section.

# STEPS
# Step 1. Make sure the class or global variable has the CommunityHelp module, 
#         check the CLASS AND OBJECT REGISTRATION section.
# Step 2. Define a "section" for help associated with a specific class. Color it blue in the Google Doc.
# Step 3. Define a unique method that starts with the name `explain_` and write your help.
# Step 4. Call the community_help function on your object and verify it works

# HELP FORMAT
# Make sure your help is formatted this way please.

=begin (this line is here as a block comment so that the formatting below can be used verbatim)

* A line that starts with an asterisks is considered a section
The body of a section immediately follows. Do not indent the paragraphs inward or anything.
** For nested sections, precede the section with an asterisk for each level of nesting
* How code should be formatted
Code should be contained in a #+begin_src delimiter and an #+end_src delimiter and be intendented (two spaces). Like so:
#+begin_src
  def this_is_some_sample_code
    puts "hello world"
  end
#+end_src

=end


# CLASS AND OBJECT REGISTRATION
# If you want to add help functionality to a global object, add the line here:

$gtk.class.include(CommunityHelp)
$gtk.args.class.include(CommunityHelp)
$gtk.args.outputs.class.include(CommunityHelp)

# If the class is an existing/core class, add the line here/like so:
class Array
  include CommunityHelp
end

class Hash
  include CommunityHelp
end



 
# ARRAY
class Array; class << self # BEGIN ARRAY CLASS AND SINGLETON CLASS



# EXPLAIN SORTING
def explain_sorting; <<-explain_sorting 
* HELP TOPIC: How to use custom sorting
Arrays support custom sorting through the `sort` and `sort_by` functions.
** Simple sort using `sort_by`
Let's say you have an array of "people" with the following structure:

#+begin_src
things_to_sort = [
  { type: :background, order: 1 },
  { type: :foreground, order: 1 },
  { type: :foreground, order: 2 }
]
#+end_src

If I wanted to do a simple sort and only consider order, I could do:

#+begin_src
results = things_to_sort.sort_by do |hash|
  hash[:order]
end
#+end_src

** Complex sort
You can do a complex sort if you provide a block to the `sort` function.

In this example, I want to sort by first whether it's a background or foreground
and then consider the order (if both :type's are the same).
#+begin_src
# for a more complicated sort, you can provide a block that returns
# -1, 0, 1 for a left and right operand
results = things_to_sort.sort do |l, r|
  sort_result = 0
  puts "here is l: \#{l}"
  puts "here is r: \#{r || "nil"}"
  # if either value is nil/false return 0
  if !l || !r
    sort_result = 0
  # if the type of "left" is background and the
  # type of "right" is foreground, then return
  # -1 (which means "left" is less than "right"
  elsif l[:type] == :background && r[:type] == :foreground
    sort_result = -1
  # if the type of "left" is foreground and the
  # type of "right" is background, then return
  #  1 (which means "left" is greater than "right"
  elsif l[:type] == :foreground && r[:type] == :background
    sort_result = 1
  # if "left" and "right"'s type are the same, then
  # use the order as the tie breaker
  elsif l[:order] < r[:order]
    sort_result = -1
  elsif l[:order] > r[:order]
    sort_result = 1
  # returning 0 means both values are equal
  else
    sort_result = 0
  end
  sort_result
end.to_a
#+end_src
explain_sorting
end   # END EXPLAIN SORTING METHOD

# NEW EXPLAIN ARRAY PLACEHOLDER





# END ARRAY
end; end  # END ARRAY CLASS AND SINGLETON CLASS

# NEW EXPLAIN CLASS PLACEHOLDER




# DANGER ZONE DO NOT CHANGE ANYTHING BELOW THIS LINE
module CommunityHelp
  def self.included klass
    @__community_help_classes__ ||= []
    @__community_help_classes__ << klass
    @__community_help_classes__.uniq!
  end

  def self.search *search_terms
    @__community_help_classes__ ||= []
    last_search_terms_set search_terms
    last_results_clear
    @__community_help_classes__.each { |klass| community_help klass, search_terms  }
    export!
    nil
  end

  def self.last_results_clear
    @last_results ||= []
    @last_results.clear
  end

  def self.puts_help help
    @last_results ||= []
    @last_results << help
    puts help
  end

  def self.last_search_terms_set *search_terms
    @last_search_terms = search_terms
  end

  def self.export!
    contents = <<-S
Search terms: #{@last_search_terms.flatten.map(&:strip).join(' ')}

Results:
#{@last_results.map(&:strip).join("\n")}
S

    file_name = "help/help_#{Time.now.to_i}.txt"
    $gtk.write_file(file_name, contents)

    puts "* INFO: If you didn't find help for the function you were looking for, go to https://tinyurl.com/dragonruby-gtk-docs and contribute."
    puts "* INFO: The search results have been saved to #{file_name}"
  end

  def self.community_help klass, *search_terms
    CommunityHelp.puts_help "* INFO: Invoking community_help on #{klass}."
    search_term = search_terms.flatten.join(' ').strip
    help_functions = klass.methods.find_all { |m| m.to_s.start_with?("explain_") }
    help_functions.each do |m|
      help_text = klass.send(m).strip
      if search_term && search_term.length > 0
        terms = search_term.split(' ').map { |t| t.strip }.reject { |t| t.length == 0 }
        if terms.any? { |t| help_text.include? t }
          CommunityHelp.puts_help help_text
        end
      else
        CommunityHelp.puts_help help_text
      end
    end
  end

  def community_help *search_terms
    CommunityHelp.community_help self.class, search_terms
    CommunityHelp.export!
  end
end

class Object
  def community_help *search_terms
    puts <<-S
* INFO: Class #{self.class} does not have community_help.
Go to https://tinyurl.com/dragonruby-gtk-docs and contribute and contribute.
S
  end
end




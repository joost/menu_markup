require 'treetop'
require "menu_markup/version"
require "menu_markup/parsed_price"

require "menu_markup_parser"

require 'active_support'
require 'active_support/core_ext/object/blank' # presence method
require 'active_support/core_ext/hash/reverse_merge' # reverse_merge! method

module MenuMarkup
  def self.parse(text)
    MenuMarkupParser.new.parse(text)
  end
end

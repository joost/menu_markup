# encoding: utf-8
#
# MenuMarkup::Parser parses our superspecial menu markup into Entries (Items and Sections).
#
# Maybe use one of these:
# http://stackoverflow.com/questions/3454047/ruby-markup-parser-for-custom-markup-language
#
# Example:
#   parser = MenuMarkup::MenuMarkupParser.new
#   result = parser.parse(File.read('spec/support/menu5.txt')).elements
#
# TODO:
# * Better implementation
# * Support 'vanaf', 'v.a.', 'per persoon', '2 personen', 'p.p.', ..
# * Recognize best price. Eg. wines often use Blablawine 2003 (year) which is recognized as Price. We should prefer 4,50 (comma seperated) above this kind of values.
#

Treetop.load(File.join(__dir__, 'menu_markup')) # MenuMarkupParser is created by Treetop

class MenuMarkupParser
  class Node < Treetop::Runtime::SyntaxNode
  end

  class Section < Node
    attr_reader :prices, :title, :description_lines

    def description
      description_lines.join("\n")
    end

    def restrictions
      attributes_node.respond_to?(:attributes) ? attributes_node.attributes.restrictions : []
    end

    def spicy
      attributes_node.respond_to?(:attributes) ? attributes_node.attributes.spicy : nil
    end

    def parse_elements!
      @description_lines = description_node.elements.collect { |node| node.text.text_value.strip }
      @prices = parse_prices!
      @title = @description_lines.shift

      children.each { |node| node.parse_elements! }
    end

    def choice?
      choice_node.text_value.present?
    end

    def children
      children_nodes.elements
    end

    private

    def parse_prices!
      parse_explicit_prices
    end

    def parse_explicit_prices
      price_lines, @description_lines = @description_lines.partition { |line| line.start_with?('=') }
      price_lines.collect { |price_line| MenuMarkup::ParsedPrice.parse_line(price_line[1..-1]) }
    end
  end

  class Item < Section
    def children
      []
    end

    private

    def parse_prices!
      parse_explicit_prices.presence || parse_price_line.presence || parse_inline_price
    end

    def parse_price_line
      new_description = description
      match = MenuMarkup::ParsedPrice.find_match(new_description, eop: /(?=$)/ui) || MenuMarkup::ParsedPrice.find_match(new_description, bop: /(?<=^)/ui)

      if match
        new_description.slice!(match.begin(0)...match.end(0))
        @description_lines = new_description.lines.collect(&:strip).reject(&:blank?)
        [MenuMarkup::ParsedPrice.new(match.to_s)]
      end
    end

    def parse_inline_price
      match = MenuMarkup::ParsedPrice.find_match(description)
      if match
        [MenuMarkup::ParsedPrice.new(match.to_s)]
      else
        [MenuMarkup::ParsedPrice.new(nil)]
      end
    end
  end

  class Attributes < Node
    SPICY_MAP = {
        'n' => 'none',
        'm' => 'mild',
        'M' => 'medium',
        'H' => 'hot', # h = halal!
    }
    RESTRICTIONS_MAP = {
        'V' => 'vegan',
        'v' => 'vegetarian',
        'k' => 'kosher',
        'h' => 'halal'
    }

    def restrictions
      map(RESTRICTIONS_MAP)
    end

    def spicy
      map(SPICY_MAP).first
    end

    private

    def map(map)
      map.values_at(*text_value.chars).compact
    end
  end

  def parse(text)
    super(text).tap { |result| result.menu.elements.each(&:parse_elements!) if result }
  end

end
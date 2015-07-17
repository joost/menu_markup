# encoding: utf-8
module MenuMarkup
  class ParsedPrice
    EOP = /(?=\s|$)/ui
    BOP = /(?<=\s|^)/ui
    DASH = /\-{1,2}|—{1,2}/ui # TODO: Support different dashes?, see: http://csswizardry.com/2010/01/the-three-types-of-dash/
    CURRENCY = /\$|€|euro?|usd|dollar|gbp|tl|£|₤/ui # tl = Turkish lira

    INTEGER = /1[0-7]\d\d|\d{1,3}/ui
    COMMA_DECIMAL = /\d+,\d/ui
    DOT_DECIMAL = /\d+\.\d/ui
    DASH_COMMA_DECIMAL = /\d+,#{DASH}/ui
    DASH_DOT_DECIMAL = /\d+\.#{DASH}/ui
    FULL_COMMA_DECIMAL = /\d+,\d\d/ui
    FULL_DOT_DECIMAL = /\d+\.\d\d/ui

    PRE_CURRENCY_INTEGER = /#{CURRENCY}\s*#{INTEGER}/ui
    POST_CURRENCY_INTEGER = /#{INTEGER}\s*#{CURRENCY}/ui

    PRE_CURRENCY_COMMA = /#{CURRENCY}\s*#{COMMA_DECIMAL}/ui
    POST_CURRENCY_COMMA = /#{COMMA_DECIMAL}\s*#{CURRENCY}/ui
    PRE_CURRENCY_DOT = /#{CURRENCY}\s*#{DOT_DECIMAL}/ui
    POST_CURRENCY_DOT = /#{DOT_DECIMAL}\s*#{CURRENCY}/ui

    PRE_CURRENCY_DASH_COMMA = /#{CURRENCY}\s*#{DASH_COMMA_DECIMAL}/ui
    POST_CURRENCY_DASH_COMMA = /#{DASH_COMMA_DECIMAL}\s*#{CURRENCY}/ui
    PRE_CURRENCY_DASH_DOT = /#{CURRENCY}\s*#{DASH_DOT_DECIMAL}/ui
    POST_CURRENCY_DASH_DOT = /#{DASH_DOT_DECIMAL}\s*#{CURRENCY}/ui

    PRE_CURRENCY_FULL_COMMA = /#{CURRENCY}\s*#{FULL_COMMA_DECIMAL}/ui
    POST_CURRENCY_FULL_COMMA = /#{FULL_COMMA_DECIMAL}\s*#{CURRENCY}/ui
    PRE_CURRENCY_FULL_DOT = /#{CURRENCY}\s*#{FULL_DOT_DECIMAL}/ui
    POST_CURRENCY_FULL_DOT = /#{FULL_DOT_DECIMAL}\s*#{CURRENCY}/ui

    LITERAL = /dagprijs/ui

    PRICES = [
        PRE_CURRENCY_FULL_COMMA, PRE_CURRENCY_FULL_DOT, PRE_CURRENCY_DASH_COMMA, PRE_CURRENCY_DASH_DOT, PRE_CURRENCY_COMMA, PRE_CURRENCY_DOT, PRE_CURRENCY_INTEGER,
        POST_CURRENCY_FULL_COMMA, POST_CURRENCY_FULL_DOT, POST_CURRENCY_DASH_COMMA, POST_CURRENCY_DASH_DOT, POST_CURRENCY_COMMA, POST_CURRENCY_DOT, POST_CURRENCY_INTEGER,
        FULL_COMMA_DECIMAL, FULL_DOT_DECIMAL, DASH_COMMA_DECIMAL, DASH_DOT_DECIMAL, COMMA_DECIMAL, DOT_DECIMAL, INTEGER,
        LITERAL
    ]

    attr_accessor :money, :title, :unit

    def self.find_match(text, options = {})
      options.reverse_merge!(eop: EOP, bop: BOP)
      PRICES.each do |regex|
        return $~ if text.scan(/#{options[:bop]}#{regex}#{options[:eop]}/ui).present?
      end
      nil
    end

    def self.parse_line(line)
      match = find_match(line)
      if match
        new(match.to_s, match.pre_match, match.post_match)
      else
        new(nil, line)
      end
    end

    def initialize(money, title = nil, unit = nil)
      # In case this is literal price, we want to set it as title of price and not money
      if money =~ LITERAL
        title = "#{title}#{money}#{unit}"
        money = nil
      end

      @money, @title, @unit = money.presence, title.presence, unit.presence
      # Replace .- with .00
      @money.gsub!(/([\.,])#{DASH}/, "\\100") if @money
    end
  end
end
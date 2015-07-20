# MenuMarkup [![Build Status](https://api.travis-ci.org/refreshingmenus/menu_markup.svg?branch=master)](https://travis-ci.org/refreshingmenus/menu_markup) [![Coverage Status](https://coveralls.io/repos/refreshingmenus/menu_markup/badge.svg)](https://coveralls.io/r/refreshingmenus/menu_markup)

Ruby gem to parse MenuMarkup. See the [MenuMarkup specification][].

MenuMarkup is a super simple markup to specify menu data in plain text. When the MenuMarkup is parsed it creates a Menu.
A Menu consists of two types: Items and Sections. Items have multiple Prices.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'menu_markup'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install menu_markup

## MenuMarkup example

For the full specs see the [MenuMarkup specification][].

```
# Lines with a # are comments!
# Empty lines are ignored

* Main dishes
The main dishes can be ordered between 17.00 and 21.00.
- Super meat 29.95 euro
This is 500 grams of pure super meat.
- Some other dish
#This dish has the price on a different line. It will be parsed correctly.
12,95
- Daily fish
#This differs every day and the price can also change.
=depends

*Dessert
- Special dessert
#This dessert has multiple sizes and prices.
= small 12,30
= large 23,30
- A desert for 2
= 12,30 per person
- 300 grams of chocolate
#To not make the price 300 we specify an empty price using '='.
=
```

## Usage

```ruby
parser = MenuMarkupParser.new
parser.parse("*Some\n-Menu\n-Markup")
```

or

```ruby
MenuMarkup.parse("*Some\n-Menu\n-Markup")
```

Next you should create some logic around the parsed content.
In the example below we have Entry, Item and Price ActiveRecord models.

```ruby
result = parser.parse(text)
result.menu.elements.collect { |element| build_entry(element) } if result

def build_entry(element)
  entry = send("build_#{element.class.to_s.demodulize.underscore}", element) # Calls build_xx method
  entry.menu = self # All models belong_to a Menu
  entry.entries = element.children.collect { |subelement| build_entry(subelement) }

  unless entry.valid?
    line = parser.input.line_of(element.interval.first)
    type = entry.class.name.humanize.downcase
    errors.add(:markup_text, "has invalid #{type} on line ##{line}: #{entry.errors.to_a.to_sentence}")
  end

  entry
end
```

Define the build_xx methods and use the parsed element content.

```ruby
def build_section(element)
  Section.new(title: element.title, desc: element.description, choice: element.choice?, prices: build_prices(element))
end

def build_item(element)
  Item.new(title: element.title, desc: element.description, spicy: element.spicy, prices: build_prices(element),
           restriction_list: element.restrictions)
end

def build_prices(element)
  # Up to the reader :)
end
```

## Development

    bundle install
    guard

## Contributing

1. Fork it ( https://github.com/[my-github-username]/menu_markup/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[MenuMarkup specification]: http://www.webuildinternet.com/2012/07/04/menu-markup-specification/
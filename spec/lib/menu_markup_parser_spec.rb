# encoding: utf-8
require 'spec_helper'

describe MenuMarkupParser do
  let :parser do
    described_class.new
  end

  it "should parse empty strings" do
    menu = parser.parse("").menu.elements
    menu.should be_instance_of(Array)
    menu.should be_empty
  end

  describe "comments" do
    it "should parse a single comment" do
      menu = parser.parse("#Some comment").menu.elements
      menu.should be_instance_of(Array)
      menu.should be_empty
    end

    it "should allow spaces before hash symbol in comment line" do
      menu = parser.parse("    #Some comment").menu.elements
      menu.should be_instance_of(Array)
      menu.should be_empty
    end
  end

  describe "sections" do
    it "should parse a single section" do
      menu = parser.parse("*Some section name").menu.elements
      menu.should be_instance_of(Array)
      menu.first.should be_instance_of(MenuMarkupParser::Section)
      menu.first.title.should == "Some section name"
    end

    it "should allow spaces between asterisk and title" do
      section = parser.parse("* \tSome section name \t").menu.elements.first
      section.title.should == "Some section name"
    end

    it "should parse section with description" do
      section = parser.parse("*Some section name\nwith a description").menu.elements.first
      section.title.should == "Some section name"
      section.description.should == "with a description"
    end

    it "should parse section with multiline description" do
      section = parser.parse("*Some section name\nwith a description\nwith multiple lines").menu.elements.first
      section.title.should == "Some section name"
      section.description.should == "with a description\nwith multiple lines"
    end

    it "should skip comments and blanks between description lines" do
      section = parser.parse("*Some section name\nwith a description\n#with a comment\n\nwith multiple lines").menu.elements.first
      section.title.should == "Some section name"
      section.description.should == "with a description\nwith multiple lines"
    end

    it "should skip comments and blanks surrounding section" do
      section = parser.parse("\n#comment\n*Some section name\nwith a description\n#comment\n").menu.elements.first
      section.title.should == "Some section name"
      section.description.should == "with a description"
    end

    it "should allow adding attributes to section" do
      section = parser.parse("*vkH*Some section name").menu.elements.first
      section.title.should == "Some section name"
      section.restrictions.should == %w(vegetarian kosher)
      section.spicy.should == 'hot'
    end

    it "should set attributes to blank if attributes node is not present" do
      section = parser.parse("*Some section name").menu.elements.first
      section.title.should == "Some section name"
      section.restrictions.should == []
      section.spicy.should be_nil
    end

    it "should allow section to have subsections" do
      section = parser.parse("*Some section\n**v**Some subsection").menu.elements.first
      section.should have(1).child
      section.children.first.should be_instance_of(MenuMarkupParser::Section)
      section.children.first.title.should == "Some subsection"
    end

    it "should allow subsection to have sub subsection" do
      section = parser.parse("**Some section\n**v**Some subsection\n***v***Some sub subsection").menu.elements.first
      subsection = section.children.first
      subsection.should have(1).child
      subsection.children.first.should be_instance_of(MenuMarkupParser::Section)
      subsection.children.first.title.should == "Some sub subsection"
    end

    it "should allow section to have items" do
      section = parser.parse("*Some section\n-Some item").menu.elements.first
      section.should have(1).child
      section.children.first.should be_instance_of(MenuMarkupParser::Item)
      section.children.first.title.should == "Some item"
    end

    it "should allow subsection to have items" do
      section = parser.parse("*Some section\n**v**Some subsection\n-Some item").menu.elements.first
      subsection = section.children.first
      subsection.should have(1).child
      subsection.children.first.should be_instance_of(MenuMarkupParser::Item)
      subsection.children.first.title.should == "Some item"
    end

    it "should allow subsection's subsection to have items" do
      section = parser.parse("*Some section\n**v**Some subsection\n***v***Some sub subsection\n-Some item").menu.elements.first
      subsection = section.children.first.children.first
      subsection.should have(1).child
      subsection.children.first.should be_instance_of(MenuMarkupParser::Item)
      subsection.children.first.title.should == "Some item"
    end

    describe "choice" do
      it "should allow marking sections with selectable items" do
        section = parser.parse("*/Some section").menu.elements.first
        section.title.should == 'Some section'
        section.should be_choice
      end

      it "should not be choice node if choice markup is not present" do
        section = parser.parse("*Some section").menu.elements.first
        section.should_not be_choice
      end

      it "should allow choice subsections" do
        section = parser.parse("*Some section\n**/Some subsection").menu.elements.first.children.first
        section.title.should == 'Some subsection'
        section.should be_choice
      end

      it "should allow choice subsections" do
        section = parser.parse("*Some section\n**Some subsection\n***/Some sub subsection").menu.elements.first.children.first.children.first
        section.title.should == 'Some sub subsection'
        section.should be_choice
      end
    end
  end

  describe "item" do
    it "should parse single item" do
      menu = parser.parse("-Some item name").menu.elements
      menu.should be_instance_of(Array)
      menu.first.should be_instance_of(MenuMarkupParser::Item)
      menu.first.title.should == "Some item name"
    end

    it "should parse item with description" do
      item = parser.parse("-Some item name\nwith a description").menu.elements.first
      item.title.should == "Some item name"
      item.description.should == "with a description"
    end

    it "should skip comments and blanks surrounding item" do
      item = parser.parse("\n#comment\n-Some item name\nwith a description\n#comment\n").menu.elements.first
      item.title.should == "Some item name"
      item.description.should == "with a description"
    end
  end

  describe "prices" do
    it "should parse price" do
      price = parser.parse("-Some item name\nwith a description\neuro 12.12\n= large 23.40 for two\n").menu.elements.first.prices.first
      price.money.should == '23.40'
      price.unit.should == ' for two'
      price.title.should == ' large '
    end

    it "should parse price for section" do
      price = parser.parse("*Some section name\n= large 23.40 for two\n").menu.elements.first.prices.first
      price.money.should == '23.40'
      price.unit.should == ' for two'
      price.title.should == ' large '
    end

    it "should allow multiple prices per item" do
      item = parser.parse("-Some item name\n= 300g for 12.50\n= 500g for 17.00\n").menu.elements.first
      item.prices.should have(2).elements
      item.prices.first.money.should == '12.50'
      item.prices[1].money.should == '17.00'
    end

    it "should find last price line in the description" do
      item = parser.parse("-Some item name\nnot price 15.5\n15.5 not price\n15.5\n20.5\n15.5 not price").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '20.5'
    end

    it "should delete price line" do
      item = parser.parse("-Some item name\ndescription\n205").menu.elements.first
      item.description.should == 'description'
    end

    it "should find price in the title" do
      item = parser.parse("-Some item name 15.5").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '15.5'
      item.title.should == 'Some item name'
    end

    it "should find price in the description" do
      item = parser.parse("-Some item name\nwith description 15.5").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '15.5'
      item.title.should == 'Some item name'
      item.description.should == 'with description'
    end

    it "should delete price at the end of line" do
      item = parser.parse("-Some item name 15.5\nwith description").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '15.5'
      item.title.should == 'Some item name'
    end

    it "should delete price at the beginning of line" do
      item = parser.parse("-15.5 Some item name\nwith description").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '15.5'
      item.title.should == 'Some item name'
    end

    it "should not delete price in title if it's not the end of line" do
      item = parser.parse("-Some item name 15.5 is price").menu.elements.first
      item.prices.first.money.should == '15.5'
      item.title.should == 'Some item name 15.5 is price'
    end

    it "should prefer last inline price" do
      item = parser.parse("-Some item name\nthis is not price 10\nprice is 20").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '20'
    end

    it "should prefer most suitable price even if it's first" do
      item = parser.parse("-Some item name\nprice is 10,00\njust a number 20").menu.elements.first
      item.prices.should have(1).element
      item.prices.first.money.should == '10,00'
    end

    it "should return empty prices if no suitable price is found" do
      item = parser.parse("-Some item name\nwith description").menu.elements.first
      item.prices.should have(1).element
      price = item.prices.first
      price.money.should be_nil
      price.title.should be_nil
      price.unit.should be_nil
    end
  end

  (1..7).each do |i|
    it "should parse menu#{i}" do
      result = parser.parse(File.read(File.join(__dir__, "../support/menu#{i}.txt"))).menu.elements
      result.should be_instance_of(Array)
      result.should_not be_empty
    end
  end
end

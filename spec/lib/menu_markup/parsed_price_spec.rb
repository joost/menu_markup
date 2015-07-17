# encoding: utf-8
require 'spec_helper'

describe MenuMarkup::ParsedPrice do
  describe "initialize" do
    it "should initialize with money, title and unit" do
      price = MenuMarkup::ParsedPrice.new('12', 'large', 'per person')
      price.money.should == '12'
      price.title.should == 'large'
      price.unit.should == 'per person'
    end

    it "should initialize with only money" do
      price = MenuMarkup::ParsedPrice.new('3.14')
      price.money.should == '3.14'
      price.title.should be_nil
      price.unit.should be_nil
    end

    it "should replace .- in price with .00" do
      price = MenuMarkup::ParsedPrice.new('2.-')
      price.money.should == '2.00'
      price.unit.should be_nil
    end

    it "should replace .-- in price with .00" do
      price = MenuMarkup::ParsedPrice.new('2.--')
      price.money.should == '2.00'
      price.unit.should be_nil
    end

    it "should replace .— in price with .00" do
      price = MenuMarkup::ParsedPrice.new('2.—')
      price.money.should == '2.00'
      price.unit.should be_nil
    end

    it "should replace .—— in price with .00" do
      price = MenuMarkup::ParsedPrice.new('2.——')
      price.money.should == '2.00'
      price.unit.should be_nil
    end

    it "should replace empty strings with nil" do
      price = MenuMarkup::ParsedPrice.new('', '', '')
      price.money.should be_nil
      price.title.should be_nil
      price.unit.should be_nil
    end
  end

  describe "find match" do
    it "should partition price to title, money and unit" do
      match = MenuMarkup::ParsedPrice.find_match('small 20,25 per person')
      match.to_s.should == '20,25'
      match.pre_match.should == 'small '
      match.post_match.should == ' per person'
    end

    it "should prefer prices at the end of line" do
      MenuMarkup::ParsedPrice.find_match('not price 20,25 price 12,70').to_s.should == '12,70'
    end

    it "should return nil if no match was found" do
      MenuMarkup::ParsedPrice.find_match('random words').should be_nil
    end

    it "should match literal price" do
      MenuMarkup::ParsedPrice.find_match('DaGpRiJs').to_s.should == 'DaGpRiJs'
    end

    describe "without currency" do
      it "should match integer" do
        MenuMarkup::ParsedPrice.find_match('DaGpRiJs 50 DaGpRiJs').to_s.should == '50'
      end

      it "should match decimal with 1 digit after dot" do
        MenuMarkup::ParsedPrice.find_match('50 50.1 50').to_s.should == '50.1'
      end

      it "should match decimal with 1 digit after comma" do
        MenuMarkup::ParsedPrice.find_match('50.1 50,1 50.1').to_s.should == '50,1'
      end

      it "should match decimal with dash after dot" do
        MenuMarkup::ParsedPrice.find_match('50,1 50.- 50,1').to_s.should == '50.-'
      end

      it "should match decimal with dash after comma" do
        MenuMarkup::ParsedPrice.find_match('50.- 50,- 50.-').to_s.should == '50,-'
      end

      it "should match decimal with 2 digits after dot" do
        MenuMarkup::ParsedPrice.find_match('50,- 50.12 50,-').to_s.should == '50.12'
      end

      it "should match decimal with 2 digits after comma" do
        MenuMarkup::ParsedPrice.find_match('50.12 50,15 50.15').to_s.should == '50,15'
      end
    end

    describe "currency after number" do
      it "should match integer" do
        MenuMarkup::ParsedPrice.find_match('50,15 abc 50$ abc 50,15').to_s.should == '50$'
      end

      it "should match decimal with 1 digit after dot" do
        MenuMarkup::ParsedPrice.find_match('50$ abc 50.1 eur abc 50$').to_s.should == '50.1 eur'
      end

      it "should match decimal with 1 digit after comma" do
        MenuMarkup::ParsedPrice.find_match('50.1$ abc 50,1€ abc 50.1$').to_s.should == '50,1€'
      end

      it "should match decimal with dash after dot" do
        MenuMarkup::ParsedPrice.find_match('50,1$ abc 50.- usd abc 50,1$').to_s.should == '50.- usd'
      end

      it "should match decimal with dash after comma" do
        MenuMarkup::ParsedPrice.find_match('50.-$ abc 50,- dollar abc 50.-$').to_s.should == '50,- dollar'
      end

      it "should match decimal with 2 digits after dot" do
        MenuMarkup::ParsedPrice.find_match('50,-$ abc 50.12 gbp abc 50,-$').to_s.should == '50.12 gbp'
      end

      it "should match decimal with 2 digits after comma" do
        MenuMarkup::ParsedPrice.find_match('50.12$ abc 50,15 £ abc 50.15$').to_s.should == '50,15 £'
      end
    end

    describe "currency before number" do
      it "should match integer" do
        MenuMarkup::ParsedPrice.find_match('50,15$ abc $50 abc 50,15$').to_s.should == '$50'
      end

      it "should match decimal with 1 digit after dot" do
        MenuMarkup::ParsedPrice.find_match('$50 abc $50.1 abc $50').to_s.should == '$50.1'
      end

      it "should match decimal with 1 digit after comma" do
        MenuMarkup::ParsedPrice.find_match('$50.1 abc $50,1 abc $50.1').to_s.should == '$50,1'
      end

      it "should match decimal with dash after dot" do
        MenuMarkup::ParsedPrice.find_match('$50,1 abc $50.- abc $50,1').to_s.should == '$50.-'
      end

      it "should match decimal with dash after comma" do
        MenuMarkup::ParsedPrice.find_match('$50.- abc $50,- abc $50.-').to_s.should == '$50,-'
      end

      it "should match decimal with 2 digits after dot" do
        MenuMarkup::ParsedPrice.find_match('$50,- abc $50.12 abc $50,-').to_s.should == '$50.12'
      end

      it "should match decimal with 2 digits after comma" do
        MenuMarkup::ParsedPrice.find_match('$50.1$ abc $50,15 abc $50.15').to_s.should == '$50,15'
      end
    end

    it "should not match partially" do
      MenuMarkup::ParsedPrice.find_match('12 europa').to_s.should == '12'
      MenuMarkup::ParsedPrice.find_match('fleur 12').to_s.should == '12'
    end

    it "should allow changing what's considered end of price" do
      MenuMarkup::ParsedPrice.find_match('12 eur ', eop: /$/).should be_nil
      MenuMarkup::ParsedPrice.find_match('12 eur', eop: /$/).to_s.should == '12 eur'
    end

    it "should not match integer higher or equal to 1800" do
      MenuMarkup::ParsedPrice.find_match('999').to_s.should == '999'
      MenuMarkup::ParsedPrice.find_match('1799').to_s.should == '1799'
      MenuMarkup::ParsedPrice.find_match('1800').should be_nil
    end
  end

  describe "parse line" do
    it "should divide line into title, money and unit" do
      price = MenuMarkup::ParsedPrice.parse_line('large 12.5 euro per person')
      price.title.should == 'large '
      price.money.should == '12.5 euro'
      price.unit.should == ' per person'
    end

    it "should parse weird prices" do
      price = MenuMarkup::ParsedPrice.parse_line('varies per day')
      price.title.should == 'varies per day'
      price.money.should be_nil
    end

    it "should set whole literal price as title" do
      price = MenuMarkup::ParsedPrice.parse_line('today is dagprijs for this')
      price.money.should be_nil
      price.title.should == 'today is dagprijs for this'
    end
  end
end

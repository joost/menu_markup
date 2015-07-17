require 'spec_helper'

describe MenuMarkup do

  before :each do
  end

  it "should parse a simple text" do
    menu = MenuMarkup.parse("* section\n- item\n").menu.elements
    expect(menu).to be_instance_of(Array)
    expect(menu.first).to be_instance_of(MenuMarkupParser::Section)
    expect(menu.first.title).to eq("section")
    expect(menu.first.children.first).to be_instance_of(MenuMarkupParser::Item)
    expect(menu.first.children.first.title).to eq("item")
  end

end
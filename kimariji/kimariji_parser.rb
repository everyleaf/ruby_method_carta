require 'csv'

class KimarijiParser
  class Card
    attr_reader :name, :reading

    def initialize(name, reading)
      @name = name
      @reading = reading
    end
  end

  attr_reader :result, :depth

  def initialize(filepath="cards.csv")
    @cards = CSV.read(filepath).map {|row| Card.new(row[0], row[1]) } # 名前、読みの順で入っている想定

    @result = group(1, @cards)
  end

  def to_s(hash = nil, indent = 0)
    string = ""
    hash ||= result
    readings = hash.keys.sort
    readings.each do |reading|
      case hash[reading]
      when Card
        string << "#{' ' * indent}#{reading}\n"
        string << "#{' ' * (indent+2)} - [#{hash[reading].name.gsub("\n", '')}]\n"
      else
        if indent == 0 || hash[reading].keys.size > 1
          string << "#{' ' * indent}#{reading}\n"
          string << to_s(hash[reading], indent+2)
        else
          string << to_s(hash[reading], indent)
        end
      end
    end
    string
  end

  def cards_count(hash)
    hash.values.map {|v| v.is_a?(Hash) ? cards_count(v) : 1}.sum
  end

  def to_csv_rows(hash = nil, indent = 0)
    rows = []
    hash ||= result
    readings = hash.keys.sort
    readings.each do |reading|
      case hash[reading]
      when Card
        row = ([''] * indent) + [reading]
        row << hash[reading].name.gsub("\n", '')
        row << hash[reading].reading
        rows << row
      else
        if indent == 0 || hash[reading].keys.size > 1
          rows << ([''] * indent) + ["#{reading} (#{cards_count(hash[reading])}枚)"]
          rows.concat(to_csv_rows(hash[reading], indent+1))
        else
          rows.concat(to_csv_rows(hash[reading], indent))
        end
      end
    end
    # すべてのrowsのセル数が同じになるように、見出し以外の行を調整する
    max_cell_size = rows.map(&:size).max
    rows.each do |row|
      unless row.last.match?(/\枚\)/)
        while row.size < max_cell_size
          row.insert(row.size-2, "")
        end
      end
    end

    rows
  end

  def write_csv(filepath)
    CSV.open(filepath, "wb") do |csv|
      to_csv_rows.each do |row|
        csv << row
      end
    end
  end

  private

  def group(index, cards)
    result = {}
    cards.each do |card|
      result[card.reading[0,index]] ||= []
      result[card.reading[0,index]] << card
    end
    depth = 1
    result.each do |reading, contents|
      if contents.size == 1
        result[reading] = contents.first
      else
        result[reading] = group(index+1, contents)
      end
    end
    result
  end
end

parser = KimarijiParser.new
puts parser.depth
parser.write_csv("kimariji.csv")
puts parser.to_s
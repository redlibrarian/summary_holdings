# TEST Summary Holdings code
#
def overlap?(a, b)
  a.include?(b.begin) || b.include?(a.begin) || a.end==b.begin || a.end+1==b.begin
end

def merge_ranges(a, b) # where ranges overlap
  [a.begin, b.begin].min...[a.end, b.end].max
end

def combine_ranges(a, b)  # for disjoint ranges
  [a, b]
end

def clean(summaryHoldings)
  summaryHoldings.each{ |range|
    range.gsub!(/\(/,"",).gsub!(/\)/,"").strip! if range.include?("(")
  }
end

def pp(range)
  if range.end == Time.now.year then
    endr = "present"
  else
    endr = range.end.to_s
  end
  return range.begin.to_s+"-"+endr
end

def pretty_print(holdings)
  range, combined, message = holdings
  if combined.empty?
    if range.class == Range
      return pp(range)+", #{message}"
    elsif range.class == Array
      combined = ""
      range.each{ |r|
        combined+=pp(r)+", "
      }
      return combined+", #{message}"
    end
  else # combined not empty
    pretty = ""
    combined.each { |a|
      pretty += pp(a)
    }
    return pretty_print([range, [], message])+pretty
  end
end

def compile(summaryHoldings)
  thresholds = []

  clean(summaryHoldings).each{ |range|
    startr, message = nil, nil
    endr = Time.now.year
    range_scan = range.scan(/\d{4}/)
    startr = range_scan.first.to_i
    endr = range_scan.last.to_i if ((range_scan.count == 2) or range.scan(/-/).empty?)
    message = range.split("-").last if (range_scan.count==1 and range.split("-").count == 2)
    thresholds << {:range =>(startr...endr), :message=>message}
  }
  thresholds
end

def merge(summaryHoldings)
  merged = summaryHoldings.first[:range]
  message = ""
  combined = []
  summaryHoldings.each { |holdings|
    merged = merge_ranges(merged, holdings[:range]) if overlap?(merged, holdings[:range])
    message = holdings[:message] if holdings[:message]
  }
  summaryHoldings.each{ |holdings|
    combined << combine_ranges(merged, holdings[:range]) unless overlap?(merged, holdings[:range])
  }
  # merged and combined will always include the *first* range (see
  # initial assignment to merged)
  return merged, combined.flatten.drop(1), message
end


summaryHoldings = ["(1956)-(1965)", "(1966)-(1999)", "(1990)-most recent 3 years unavailable", "(1995)", "(2000)-"]
puts pretty_print(merge(compile(summaryHoldings)))
puts "======="
summaryHoldings = ["(1956)-(1960)", "(1966)-(1999)"]
puts pretty_print(merge(compile(summaryHoldings)))

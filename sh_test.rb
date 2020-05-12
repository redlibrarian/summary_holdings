def overlap?(a, b)
  a.include?(b.begin) || b.include?(a.begin) || a.end==b.begin || a.end+1==b.begin #this last to cover the fact that years have thickness
end

def merge_ranges(a, b) # where ranges overlap
  [a.begin, b.begin].min...[a.end, b.end].max
end

def combine_ranges(a, b)  # for disjoint ranges
  [a, b]
end

def clean(summaryHoldings)
  summaryHoldings.each{ |range|
    range.gsub(/\(/,"",).gsub(/\)/,"").strip if range.include?("(")
  }
end

def pp(range)  # pretty-print an individual range
  (range.end == Time.now.year) ? endr = "present" : endr = range.end.to_s
  range.begin.to_s+"-"+endr
end

def pretty_print(holdings) # pretty-print the whole summary_holdings statement
  range, combined, message = holdings
  statement = ""
  if combined.empty?
    statement = pp(range)
  else # combined not empty
    pretty = ""
    combined.each { |a|
      pretty += pp(a)
    }
    statement = pretty_print([range, [], message])+pretty
  end
  statement+", #{message}"
end

def compile(summaryHoldings)
  thresholds = []

  clean(summaryHoldings).each{ |range|
    range_scan = range.scan(/\d{4}/)
    startr = range_scan.first.to_i
    (range_scan.count == 2 or range.scan(/-/).empty?) ? endr = range_scan.last.to_i : endr = Time.now.year
    message = range.split("-").last if (range_scan.count==1 and range.split("-").count == 2)
    thresholds << {:range =>(startr...endr), :message=>message}
  }
  thresholds
end

def merge(summaryHoldings)
  merged = summaryHoldings.first[:range]
  message = ""
  combined = []

  # merge overlapping ranges
  summaryHoldings.each { |holdings|
    merged = merge_ranges(merged, holdings[:range]) if overlap?(merged, holdings[:range])
    message = holdings[:message] if holdings[:message] # this only needs to be done once
  }

  # combine disjoint ranges
  summaryHoldings.each{ |holdings|
    combined << combine_ranges(merged, holdings[:range]) unless overlap?(merged, holdings[:range])
  }

  return merged, combined.flatten.drop(1), message  # drop(1) to get rid of the duplicated first range 
end

# all overlap, with embargo (embargo superseded by "present"): not
# working, should be: 1956-present
summaryHoldings = ["(1956)-(1965)", "(1966)-(1999)", "(1990)-most recent 3 years unavailable", "(1995)", "(2000)-"]
puts pretty_print(merge(compile(summaryHoldings)))
# all overlap, with correct embargo: this works.
summaryHoldings = ["(1956)-(1965)", "(1966)-(1999)", "(1990)-most recent 3 years unavailable", "(1995)", "(2000)"]
puts pretty_print(merge(compile(summaryHoldings)))
# none overlap/disjoint closed: this works (trailing comma)
summaryHoldings = ["(1956)-(1960)", "(1966)-(1999)"]
puts pretty_print(merge(compile(summaryHoldings)))
# disjoint, open-ended: this works (trailing comma)
summaryHoldings = ["(1956)-(1960)", "(1966)-"]
puts pretty_print(merge(compile(summaryHoldings)))
# overlap closed: this works
summaryHoldings = ["(1966)-(1999)", "(1990)-(2010)"]
puts pretty_print(merge(compile(summaryHoldings)))
# one disjoint, one overlap: not working, should be 1956-1960, 1966-2010
summaryHoldings = ["(1956)-(1960)", "(1966)-(1999)", "(1990)-(2010)"]
puts pretty_print(merge(compile(summaryHoldings)))
# one disjoint, one overlap, open-ended: not working, should be
# 1956-1960, 1966-present
summaryHoldings = ["(1956)-(1960)", "(1966)-(1999)", "(1990)-"]
puts pretty_print(merge(compile(summaryHoldings)))

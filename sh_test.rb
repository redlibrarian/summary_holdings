module SummaryHoldings

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
        pretty += ", #{pp(a)}"
      }
      statement = pretty_print([range, [], nil])+pretty
    end
    (message.nil? or message.empty?) ? statement : statement+", #{message}"
  end

  def compile(summaryHoldings)
    thresholds = []

    clean(summaryHoldings).each{ |range|
      embargo = false
      range_scan = range.scan(/\d{4}/)
      startr = range_scan.first.to_i
      message = range.split("-").last if (range_scan.count==1 and range.split("-").count == 2)
      (range_scan.count == 2 or range.scan(/-/).empty?) ? endr = range_scan.last.to_i : endr = Time.now.year
      embargo = true if message
      thresholds << {:range =>(startr...endr), :message=>message, :embargo=>embargo}
    }
    thresholds
  end

  def merge(summaryHoldings)
    merged = summaryHoldings.first[:range]
    message = ""
    combined = []
    override_embargo = false

    # merge overlapping ranges
    summaryHoldings.each { |holdings|
      merged = merge_ranges(merged, holdings[:range]) if overlap?(merged, holdings[:range])
      message = holdings[:message] if holdings[:message] # this only needs to be done once
      override_embargo = true if (holdings[:range].end == Time.now.year and holdings[:embargo] == false)
    }

    # combine disjoint ranges
    summaryHoldings.each{ |holdings|
      combined << combine_ranges(merged, holdings[:range]) unless overlap?(merged, holdings[:range])
    }

    combined = combined.flatten.uniq.reject{|a| overlap?(merged, a)}


    if override_embargo
      return merged, combined, nil
    else
      return merged, combined, message
    end
  end
end


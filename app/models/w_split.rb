module WSplit
  class Run < Run
    def self.sti_name
      :wsplit
    end
  end

  class Split < Split
  end

  class Parser < BabelBridge::Parser
    rule :wsplit_file, :title_line, :attempts_line, :offset_line, :size_line, many?(:splits), :icons_line

    rule :title_line,    'Title=',     :title,    :newline
    rule :attempts_line, 'Attempts=',  :attempts, :newline
    rule :offset_line,   'Offset=',    :offset,   :newline
    rule :size_line,     'Size=',      :size,     :newline
    rule :splits,        :title,       ',',       :old_time, ',', :finish_time, ',', :best_time, :newline
    rule :icons_line,    'Icons=',     /(.*)/,    :newline?

    rule :title,    /([^,\r\n]*)/
    rule :attempts, /(\d+)/
    rule :offset,   /(\d*\.?\d*)/
    rule :size,     /([^\r\n]*)/

    rule :old_time,    :time
    rule :finish_time, :time
    rule :best_time,   :time

    rule :time,    /([\d\.]+)/

    rule :newline,         :windows_newline
    rule :newline,         :unix_newline
    rule :windows_newline, "\r\n"
    rule :unix_newline,    "\n"

    def parse(file)
      (run = super(file)) && {
        name: run.title.to_s,
        attempts: run.attempts.to_s.to_i,
        offset: run.offset.to_f,
        splits: parse_splits(run.splits)
      }
    end

    private

    def parse_splits(splits)
      splits.map.with_index do |split, index|
        parse_split(split, index == 0 ? 0 : preceding_unskipped_split(splits, index).try(:finish_time).to_s.to_f)
      end
    end

    def parse_split(segment, prev_split_finish_time)
      Split.new(
        best: Split.new(duration: segment.best_time.to_s.to_f),
        name: segment.title.to_s,
        duration: [segment.finish_time.to_s.to_f - prev_split_finish_time, 0].max,
        finish_time: segment.finish_time.to_s.to_f
      ).tap do |split|
        split.gold = split.duration > 0 && split.duration.round(5) == split.best.duration.try(:round, 5)
        split.skipped = split.duration == 0
      end
    end

    def preceding_unskipped_split(splits, i)
      splits[0...i].reverse.map do |split, j|
        return split if split.finish_time.to_s.to_f != 0
      end.last
    end
  end
end

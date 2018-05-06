module Process
  # http://t-a-w.blogspot.ru/2010/04/how-to-kill-all-your-children.html
  # also check https://unix.stackexchange.com/a/299198
  def self.descendant_processes(base = Process.pid)
    descendants = Hash.new{ |ht,k| ht[k] = [k] }
    Hash[*`ps -eo pid,ppid`.scan(/\d+/).map(&:to_i)].each do |pid, ppid|
      descendants[ppid] << descendants[pid]
    end

    descendants[base].flatten - [base]
  end
end

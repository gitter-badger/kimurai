class String


# File activesupport/lib/active_support/inflector/methods.rb, line 67
    def camelize(term, uppercase_first_letter = true)
      string = term.to_s
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { inflections.acronyms[$&] || $&.capitalize }
      else
        string = string.sub(/^(?:#{inflections.acronym_regex}(?=\b|[A-Z_])|\w)/) { $&.downcase }
      end
      string.gsub!(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
      string.gsub!(/\//, '::')
      string
    end



  def to_crawler_class(string)
    string.sub(/^./) { $&.capitalize }
      .gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
      .gsub(/(?:-|(\/))([a-z\d]*)/) { "Dash#{$2.capitalize}" }
      .gsub(/(?:\.|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
  end
end

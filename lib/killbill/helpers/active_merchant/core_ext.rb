# Thank you Rails!
class String
  def camelize(uppercase_first_letter = true)
    string = to_s
    if uppercase_first_letter
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
    else
      string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
    end
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    string.gsub!('/', '::')
    string
  end unless respond_to?(:camelize)
end

class Integer
  def base(b)
    self < b ? [self] : (self/b).base(b) + [self%b]
  end
end

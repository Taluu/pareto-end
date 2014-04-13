# from http://bloerg.net/2013/03/03/typographic-improvements-for-jekyll.html
require 'typogruby'
require 'jekyll'

class Jekyll::Converters::Markdown
    def convert(content)
        setup
        content.gsub!(/^-- view more --$/, '')
        return Typogruby.improve(@parser.convert content)
    end
end


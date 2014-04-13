# from https://github.com/navarroj/krampygs
require 'jekyll'
require 'pygments'
require 'kramdown'

class Kramdown::Converter::Pygs < Kramdown::Converter::Html
    def convert_codeblock(el, indent)
        attr = el.attr.dup
        lang = extract_code_language!(attr) || @options[:coderay_default_lang]
        code = pygmentize(el.value, lang)

        code_attr = {}
        code_attr['class'] = "language-#{lang}" if lang

        "#{' '*indent}<pre#{html_attributes(attr)}><code#{html_attributes(code_attr)}>#{code}</code></pre>\n"
    end

    def convert_codespan(el, indent)
        attr = el.attr.dup
        lang = extract_code_language!(attr) || @options[:coderay_default_lang]
        code = pygmentize(el.value, lang)

        if lang
            if attr.has_key?('class')
                attr['class'] += " language-#{lang}"
            else
                attr['class'] = "language-#{lang}"
            end
        end

        "<code#{html_attributes(attr)}>#{code}</code>"
    end

    def pygmentize(code, lang)
        if lang
            Pygments.highlight(code,
                :lexer => lang,
                :options => { :encoding => 'utf-8', :nowrap => true })
        else
            escape_html(code)
        end
    end
end

class Jekyll::Converters::Markdown::KramdownParser
    def convert(content)
        Kramdown::Document.new(content, @config["kramdown"].symbolize_keys).to_pygs
    end
end

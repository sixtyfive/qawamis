require 'execjs'

def convert_js_to_txt(input_file)
  output_file = input_file.gsub(/\.js$/, '.txt')
  print "#{input_file} => #{output_file}"
  if File.exist? output_file
    puts " (already exists)"
    return
  end
  book_name = File.basename(input_file, '.js')
  context = ExecJS.compile(File.read(input_file))
  roots = context.eval(book_name)
  if roots.is_a? Array
    File.write(output_file, roots.join("\n"))
    puts
    true
  else
    puts " (error reading input)"
    false
  end
end

desc 'convert all data/dictionaries/indices/*.js for which no .txt exists, to .txt'
namespace :ejtaal do
  task :convert_js do |t|
    Dir.glob("data/dictionaries/indices/*.js").each{|f| convert_js_to_txt(f)}
  end
end

require 'date'

IS_DRY_RUN = false
#IS_DRY_RUN = true
FOLDER = "_posts"

Dir.glob(FOLDER + '/**').select{ |e| File.file?(e) }.each do |file|
  file = file.gsub("#{FOLDER}/", '')
  #puts file

  new_file_name = file.gsub('(', '-').gsub(')', '-').gsub('（', '-').gsub('）', '-').gsub('：', '-').gsub('，', '-')
    .gsub(' ', '-').gsub(':', '-').gsub('.', '-').gsub('>', '-').gsub('<', '-')
    .gsub('.', '-').gsub('!', '-').gsub('。', '-').gsub('？', '-').gsub('_', '-')
    .gsub('、', '-').gsub(',', '-').gsub("'", '-').gsub('　', '-')
    .gsub('-html', '.html')

  `cd #{FOLDER} && mv '#{file}' '#{new_file_name}'`
end



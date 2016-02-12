require 'rubygems'
require 'json'

def init_best_char (file)
  new_array = []
  (97..122).each do |i|
    char_hash = {}
    char_hash['letter'] = i.chr
    char_hash['best_score'] = 0x3f3f3f
    char_hash['amount'] = 0
    char_hash['average'] = 0
    new_array << char_hash
  end
  file.write new_array.to_json
end

def init_best_word (file)
  new_array = []
  file.write new_array.to_json
end

def count_spent_time (hash)
  task_start_time = hash['task_start_time']#double
  end_time = hash['end_time']#double
  end_time - task_start_time
end

run lambda { |env|
  if env['REQUEST_URI'] == '/post'

    #read in and add to old hash
    content = env['rack.input'].read.to_s
    begin
      hash = JSON.parse content
    rescue
      return ['200', {'Content-Type' => 'text/html'}, ['incorrect_json_format']]
    end

    file = File.open('data/main', 'r')
    old_content = file.read.to_s
    file.close
    file = File.open('data/main', 'w')
    if old_content == ''
      old_array = []
    else
      old_array = JSON.parse old_content
    end
    old_array << hash
    file.write old_array.to_json
    file.close

    #update best scores for single letters
    best_file = File.open('data/best_char', 'r')
    old_best_content = best_file.read.to_s
    best_file.close

    if old_best_content == ''#no data
      best_file = File.open('data/best_char', 'w')
      init_best_char best_file
      best_file.close
    end

    best_file = File.open('data/best_char', 'r')
    old_best_content = best_file.read.to_s
    best_file.close
    old_best_array = JSON.parse old_best_content
    char_tasks = hash['char_task']#array
    char_tasks.each do |task|#hash
      mode = task['mode']#int
      if mode == 1#reciting mode
        letter = task['letter']#string
        spent_time = count_spent_time task
        single_hash = old_best_array[letter.ord - 'a'.ord]
        single_hash['best_score'] = [single_hash['best_score'], spent_time].min
        single_hash['average'] = (single_hash['average'] * single_hash['amount'] + spent_time) /
            (single_hash['amount'] + 1)
        single_hash['amount'] += 1
      end
    end
    best_file = File.open('data/best_char', 'w')
    best_file.write old_best_array.to_json
    best_file.close

    #update best scores for words
    best_file = File.open('data/best_word', 'r')
    old_best_content = best_file.read.to_s
    best_file.close

    if old_best_content == ''#no data
      best_file = File.open('data/best_word', 'w')
      init_best_word best_file
      best_file.close
    end

    best_file = File.open('data/best_word', 'r')
    old_best_content = best_file.read.to_s
    best_file.close
    old_best_array = JSON.parse old_best_content
    words = hash['word']#array
    words.each do |word|#hash
      is_new_word = true
      old_best_array.each do |single_word|#hash
        if single_word['word'] == word['word']
          spent_time = count_spent_time word
          is_new_word = false
          single_word['best_score'] = [single_word['best_score'], spent_time].min
          single_word['average'] = (single_word['average'] * single_word['amount'] + spent_time) /
              (single_word['amount'] + 1)
          single_word['amount'] += 1
          break
        end
      end
      if is_new_word
        new_word = {}
        spent_time = count_spent_time word
        new_word['word'] = word['word']
        new_word['amount'] = 1
        new_word['average'] = spent_time
        new_word['best_score'] = spent_time
        old_best_array << new_word
      end
    end
    best_file = File.open('data/best_word', 'w')
    best_file.write old_best_array.to_json
    best_file.close

    ['200', {'Content-Type' => 'text/html'}, ['success']]
  elsif env['REQUEST_URI'] == '/best/char'
    file = open('data/best_char', 'r')
    content = file.read.to_s
    ['200', {'Content-Type' => 'text/html'}, [content]]
  elsif env['REQUEST_URI'] == '/best/word'
    file = open('data/best_word', 'r')
    content = file.read.to_s
    ['200', {'Content-Type' => 'text/html'}, [content]]
  end
}
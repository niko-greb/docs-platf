#!/usr/bin/env ruby
# frozen_string_literal: true

begin
    require 'asciidoctor/doctest'
  rescue LoadError => e
    puts "❌ Ошибка загрузки: #{e.message}"
    puts "Убедитесь, что гем asciidoctor-doctest установлен."
    exit 1
  end
  
  files = ARGV.any? ? ARGV : Dir.glob('**/*.adoc')
  
  errors = 0
  
  files.each do |file|
    puts "\n📄 Testing file: #{file}"
    begin
      Asciidoctor::Doctest.test_file(file)
      puts "✅ OK"
    rescue => e
      puts "❌ FAILED: #{e.message}"
      errors += 1
    end
  end
  
  exit(errors > 0 ? 1 : 0)
#!/usr/bin/env ruby
# .repo/ci/scripts/validate-asciidoc.rb

require 'asciidoctor'

file = ARGV[0]
abort "Usage: #{$0} <file.adoc>" unless file

# Собираем все сообщения
messages = []

# Создаём кастомный логгер
logger = Logger.new(nil)
logger.formatter = proc do |severity, datetime, progname, msg|
  messages << { severity: severity, message: msg }
  ""
end

begin
  Asciidoctor.convert_file(
    file,
    safe: :secure,
    to_file: false,
    logger: logger,
    failure_level: :WARN  # ← завершить с ошибкой при WARN и выше
  )
rescue StandardError => e
  warn "FATAL: Exception while parsing #{file}: #{e.message}"
  exit 1
end

# Если дошли сюда — Asciidoctor не упал, но мог быть WARN
# failure_level=:WARN гарантирует exit code ≠ 0 при предупреждениях
# Но на всякий случай проверим вручную:
if messages.any? { |m| %w[WARN ERROR FATAL].include?(m[:severity]) }
  messages.each do |m|
    warn "#{m[:severity]}: #{m[:message]}"
  end
  exit 1
end
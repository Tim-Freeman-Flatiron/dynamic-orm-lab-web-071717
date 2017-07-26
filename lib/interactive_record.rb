require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  
	def initialize(options={})
		options.each do |key, value|
			self.send("#{key}=", value)
		end
	end

	def self.table_name
		self.to_s.downcase.pluralize
	end

	def self.column_names
		sql = "PRAGMA table_info('#{table_name}')"

		columns = []
		array = DB[:conn].execute(sql)
		array.each do |hash|
			columns << hash["name"]
		end
		columns.compact
	end

	def table_name_for_insert
		self.class.table_name
	end

	def col_names_for_insert
		self.class.column_names.delete_if {|col| col == "id"}.join(", ")
	end

	def values_for_insert
		values = []
		self.class.column_names.each do |col|
		values <<	"'#{send(col)}'" unless send(col).nil?
		end
		values.join(', ')
	end

	def save
		sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"

		DB[:conn].execute(sql)

		@id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
	end

	def self.find_by_name(name)
		sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
		DB[:conn].execute(sql, name)
	end

	def self.find_by(attribute_hash)
		attribute_hash.map do |key, value|
			sql = "SELECT * FROM #{self.table_name} WHERE #{key} = ?"
			DB[:conn].execute(sql, value)[0]
		end
	end



end
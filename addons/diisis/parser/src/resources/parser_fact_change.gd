class_name ParserFactChange
extends Resource

## Helper resource used by [method Parser.change_fact_through_res].

enum DataType {
	Bool,
	Int
}

@export var fact_name : String
@export var data_type : DataType = DataType.Bool
@export var value : Variant # variant exporting is a 4.5 thing

func _init(p_fact_name = "", p_data_type = DataType.Bool, p_value = true):
	fact_name = p_fact_name
	data_type = p_data_type
	value = p_value

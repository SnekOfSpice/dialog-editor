class_name ParserFactChange
extends Resource

## Helper resource used by [method Parser.change_fact_through_res].

enum DataType {
	Bool,
	Int
}

var fact_name : String
var data_type : DataType = DataType.Bool
var value : Variant

func _init(p_fact_name = "", p_data_type = DataType.Bool, p_value = true):
	fact_name = p_fact_name
	data_type = p_data_type
	value = p_value

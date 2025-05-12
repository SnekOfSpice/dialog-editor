@tool
extends Control

func init():
	find_child("Evaluator Paths").init()
	find_child("Arguments").init()

library todos; // library must be added and unique to add all routes in it

import 'package:cruky/cruky.dart';

List<Map> todos = [
  {"id": 1, "task": "task 1"},
  {"id": 2, "task": "task 2"},
];

class Todo {
  String task;
  bool isCompleted;
  Todo({
    required this.task,
    this.isCompleted = false,
  });
}

/// serving the routes to http server
/// with hot reloading.
void main() => serve();

@Route.get('/list/')
Future<List> listTodos() async => todos;

/// get the id from path parameters you can define `:id(int)` or `:id(string)` or `:id(double)`
/// , the parameter formate is `:nameOfField(type)` and the type is optional the default is string
@Route.get('/:id(int)/')
Future<Map> getTodo(int id) async {
  if (id < todos.length) return todos[id];
  return {
    #status: 404,
    "msg": "todo not found",
  };
}

/// get the task from form, there is two ways two to define request form type.
///
/// First is `FormRequest` form regular form request
/// , And secons is `iFormRequest` for multipart form
@Route.post('/')
Future<List> createTodo(Todo todo) async {
  Map newTodo = {"id": todos.length + 1};
  newTodo.addAll({"task": todo.task, "isCompleted": todo.isCompleted});
  todos.add(newTodo);
  return todos;
}

/// get the id fro path parameters
@Route.delete('/:id(int)')
Map deleteTodo(int id) {
  todos.removeAt(id);

  /// return custom status code
  return {
    #status: HttpStatus.ok,
    #body: {"msg": "the todo is deleted"}
  };
}

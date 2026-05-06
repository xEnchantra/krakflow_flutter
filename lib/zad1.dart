import 'dart:convert';

void main() {
  String jsonText = '[1, 5, 8, 3, 2]';
  List<dynamic> data = jsonDecode(jsonText);

  int suma = 0;
  for (var liczba in data) {
    print(liczba);
    suma += liczba as int;
  }
  print("Suma: $suma\n");

  /////////
  String jsonText2 = '{"group": "Dart", "students": ["Ola", "Adam", "Kasia"]}';
  var data2 = jsonDecode(jsonText2);

  print('Grupa: ${data2["group"]}');
  print('Studenci:');
  for (var student in data2["students"]) {
    print(student);
  }
  print("\n");

  /////////
  String jsonText3 = '{"product": {"name": "Laptop", "price": "3500"}}';
  var data3 = jsonDecode(jsonText3);

  print('Nazwa: ${data3["product"]["name"]}, Cena: ${data3["product"]["price"]}');
}


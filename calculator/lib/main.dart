import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import './CalculatorBloc.dart';

void main() {
  runApp(Calculator());
}

class Calculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Calculator",
        home: BlocProvider(
          create: (context) => CalculatorBloc(),
          child: MainPage(),
        ));
  }
}

List<Widget> generateButtons(List symbolList, BuildContext context) {
  List<Widget> _buttons = List.generate(symbolList.length, (index) {
    return ElevatedButton(
      onPressed: () {
        BlocProvider.of<CalculatorBloc>(context)
            .add(AddDigitEvent((symbolList[index] == "√"
                    ? "r"
                    : symbolList[index] == "nⁱ"
                        ? "^"
                        : symbolList[index])
                .toString()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: getColor(symbolList[index]),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Center(
        child: symbolList[index] == "ce"
            ? const Icon(
                CupertinoIcons.delete_solid,
                color: Colors.white,
              )
            : symbolList[index] == "c"
                ? const Icon(
                    CupertinoIcons.back,
                    color: Colors.white,
                  )
                : Text(
                    '${symbolList[index]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      // letterSpacing: -1,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
      ),
    );
  });

  return _buttons;
}

Color getColor(String symbol) {
  Color _color = const Color.fromARGB(255, 44, 40, 40);

  switch (symbol) {
    case "c" || "ce":
      _color = Color.fromARGB(255, 208, 66, 15);
    case "nⁱ" || "√" || "+" || "-" || "*" || "/":
      _color = Color.fromARGB(255, 208, 108, 15);
    case "=":
      _color = Color.fromARGB(255, 208, 147, 15);
  }

  return _color;
}

class MainPage extends StatelessWidget {
  final List<String> _butnSymbolList = [
    "nⁱ",
    "√",
    "c",
    "ce",
    "+",
    "1",
    "2",
    "3",
    "-",
    "4",
    "5",
    "6",
    "*",
    "7",
    "8",
    "9",
    "/",
    "0",
    ".",
    "="
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculator"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          height: 600,
          width: 300,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 21, 20, 20),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  heightFactor: 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 45, 45, 45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocBuilder<CalculatorBloc, String>(
                      builder: (context, state) {
                        return Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              child: Text(
                                state,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: GridView.count(
                    padding: EdgeInsets.only(top: 30),
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    children: generateButtons(_butnSymbolList, context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

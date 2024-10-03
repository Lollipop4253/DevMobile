import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorEvent {
  const CalculatorEvent();
}

class AddDigitEvent extends CalculatorEvent {
  final String digit;

  const AddDigitEvent(this.digit);
}

class CalculatorBloc extends Bloc<CalculatorEvent, String> {
  CalculatorBloc() : super('') {
    on<AddDigitEvent>((event, emit) {
      String currentState = state;

      if (event.digit == "=") {
        try {
          if (RegExp(r'/0(?!\.)').hasMatch(currentState)) {
            emit("Ошибка: деление на ноль");
          } else if (["+", "-", "*", "/", "^"]
              .contains(currentState[currentState.length - 1])) {
          } else {
            Expression exp = Parser().parse(currentState);
            var result = exp.evaluate(EvaluationType.REAL, ContextModel());

            if (result is double && result == result.toInt()) {
              emit(result.toInt().toString());
            } else {
              emit(result.toString());
            }
          }
        } catch (e) {
          emit("Ошибка");
        }
      } else if (event.digit == "ce") {
        emit('');
      } else if (event.digit == "c") {
        if (currentState.isNotEmpty) {
          String updatedState =
              currentState.substring(0, currentState.length - 1);
          if (updatedState.endsWith(".")) {
            updatedState = updatedState.substring(0, updatedState.length - 1);
          }
          emit(updatedState);
        }
      } else if (event.digit == ".") {
        String lastNumber = currentState.split(RegExp(r'[+\-*/^]')).last;

        if (lastNumber.contains(".")) {
        } else if (lastNumber.isEmpty) {
          emit(currentState + "0.");
        } else {
          emit(currentState + event.digit);
        }
      } else if (event.digit == "r") {
        if (currentState.isNotEmpty) {
          try {
            Expression exp = Parser().parse(currentState);
            var number = exp.evaluate(EvaluationType.REAL, ContextModel());
            if (number < 0) {
              emit("Ошибка: отрицательный корень");
            } else {
              var result = sqrt(number);
              if (result == result.toInt()) {
                emit(result.toInt().toString());
              } else {
                emit(result.toString());
              }
            }
          } catch (e) {
            emit("Ошибка");
          }
        }
      } else if (["+", "-", "*", "/", "^"].contains(event.digit)) {
        if (currentState.isEmpty) {
        } else if (currentState.endsWith(".")) {
          emit(
              currentState.substring(0, currentState.length - 1) + event.digit);
        } else if (["+", "-", "*", "/", "^"]
            .contains(currentState[currentState.length - 1])) {
          emit(
              currentState.substring(0, currentState.length - 1) + event.digit);
        } else {
          emit(currentState + event.digit);
        }
      } else {
        emit(currentState + event.digit);
      }
    });
  }
}

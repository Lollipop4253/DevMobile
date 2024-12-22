final Map<String, Map<String, double>> timeConversions = {
  "Секунды": {
    "Минуты": 1 / 60,
    "Часы": 1 / 3600,
    "Дни": 1 / 86400,
    "Недели": 1 / 604800,
    "Месяца": 1 / 2.628e6,
    "Года": 1 / 3.154e7
  },
  "Минуты": {
    "Секунды": 60,
    "Часы": 1 / 60,
    "Дни": 1 / 1440,
    "Недели": 1 / 10080,
    "Месяца": 1 / 43800,
    "Года": 1 / 525600
  },
  "Часы": {
    "Секунды": 3600,
    "Минуты": 60,
    "Дни": 1 / 24,
    "Недели": 1 / 168,
    "Месяца": 1 / 730,
    "Года": 1 / 8760
  },
  "Дни": {
    "Секунды": 86400,
    "Минуты": 1440,
    "Часы": 24,
    "Недели": 1 / 7,
    "Месяца": 1 / 30.417,
    "Года": 1 / 365
  },
  "Недели": {
    "Секунды": 604800,
    "Минуты": 10080,
    "Часы": 168,
    "Дни": 7,
    "Месяца": 1 / 4.345,
    "Года": 1 / 52.143
  },
  "Месяца": {
    "Секунды": 2.628e6,
    "Минуты": 43800,
    "Часы": 730,
    "Дни": 30.417,
    "Недели": 4.345,
    "Года": 1 / 12
  },
  "Года": {
    "Секунды": 3.154e7,
    "Минуты": 525600,
    "Часы": 8760,
    "Дни": 365,
    "Недели": 52.143,
    "Месяца": 12
  },
};

final Map<String, Map<String, double>> weightConversions = {
  "Килограмм": {"Грамм": 1000, "Центнер": 0.01, "Тонна": 0.001},
  "Грамм": {"Килограмм": 0.001, "Центнер": 0.00001, "Тонна": 0.000001},
  "Центнер": {"Килограмм": 100, "Грамм": 100000, "Тонна": 0.1},
  "Тонна": {"Килограмм": 1000, "Грамм": 1000000, "Центнер": 10},
};

final Map<String, Map<String, double>> distanceConversions = {
  "Метры": {
    "Миллиметры": 1000,
    "Сантиметры": 100,
    "Дециметры": 10,
    "Километры": 0.001,
    "Миля (сухопутная)": 0.000621371,
    "Миля (морская)": 0.000539957
  },
  "Миллиметры": {
    "Метры": 0.001,
    "Сантиметры": 0.1,
    "Дециметры": 0.01,
    "Километры": 1e-6,
    "Миля (сухопутная)": 6.2137e-7,
    "Миля (морская)": 5.3996e-7
  },
  "Сантиметры": {
    "Метры": 0.01,
    "Миллиметры": 10,
    "Дециметры": 0.1,
    "Километры": 1e-5,
    "Миля (сухопутная)": 6.2137e-6,
    "Миля (морская)": 5.3996e-6
  },
  "Дециметры": {
    "Метры": 0.1,
    "Миллиметры": 100,
    "Сантиметры": 10,
    "Километры": 0.0001,
    "Миля (сухопутная)": 6.2137e-5,
    "Миля (морская)": 5.3996e-5
  },
  "Километры": {
    "Метры": 1000,
    "Миллиметры": 1e6,
    "Сантиметры": 1e5,
    "Дециметры": 1e4,
    "Миля (сухопутная)": 0.621371,
    "Миля (морская)": 0.539957
  },
  "Миля (сухопутная)": {
    "Метры": 1609.34,
    "Миллиметры": 1.609e6,
    "Сантиметры": 1.609e5,
    "Дециметры": 1.609e4,
    "Километры": 1.60934,
    "Миля (морская)": 0.868976
  },
  "Миля (морская)": {
    "Метры": 1852,
    "Миллиметры": 1.852e6,
    "Сантиметры": 1.852e5,
    "Дециметры": 1.852e4,
    "Километры": 1.852,
    "Миля (сухопутная)": 1.15078
  },
};

Map<String, Map<String, Function(double)>> temperatureConversions = {
  "Цельсий": {
    "Кельвин": (double value) => value + 273.15,
    "Фаренгейт": (double value) => value * 9 / 5 + 32,
  },
  "Кельвин": {
    "Цельсий": (double value) => value - 273.15,
    "Фаренгейт": (double value) => (value - 273.15) * 9 / 5 + 32,
  },
  "Фаренгейт": {
    "Цельсий": (double value) => (value - 32) * 5 / 9,
    "Кельвин": (double value) => (value - 32) * 5 / 9 + 273.15,
  },
};
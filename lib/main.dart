import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Measurement Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Changed to a more vibrant color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'MeasureMint'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCategory = 'Length/Distance';
  String _fromUnit = 'Meter (m)';
  String _toUnit = 'Kilometer (km)';
  double _value = 0.0;
  double _result = 0.0;

  final List<String> _categories = [
    'Length/Distance',
    'Mass/Weight',
    'Volume',
    'Area',
    'Temperature',
    'Speed',
    'Time',
    'Energy',
    'Power',
    'Pressure',
    'Data',
    'Fuel Economy'
  ];

  final Map<String, Map<String, double>> _units = {
    'Length/Distance': {
      'Meter (m)': 1.0,
      'Kilometer (km)': 1000.0,
      'Centimeter (cm)': 0.01,
      'Millimeter (mm)': 0.001,
      'Mile (mi)': 1609.34,
      'Yard (yd)': 0.9144,
      'Foot (ft)': 0.3048,
      'Inch (in)': 0.0254,
      'Nautical mile (nmi)': 1852.0,
    },
    'Mass/Weight': {
      'Kilogram (kg)': 1.0,
      'Gram (g)': 0.001,
      'Milligram (mg)': 0.000001,
      'Pound (lb)': 0.453592,
      'Ounce (oz)': 0.0283495,
      'Stone (st)': 6.35029,
      'Tonne (t)': 1000.0,
    },
    'Volume': {
      'Liter (L)': 1.0,
      'Milliliter (mL)': 0.001,
      'Gallon (gal) - US': 3.78541,
      'Gallon (gal) - UK': 4.54609,
      'Quart (qt)': 0.946353,
      'Pint (pt)': 0.473176,
      'Cup': 0.236588,
      'Fluid ounce (fl oz)': 0.0295735,
      'Tablespoon (tbsp)': 0.0147868,
      'Teaspoon (tsp)': 0.00492892,
    },
    'Area': {
      'Square meter (m²)': 1.0,
      'Square kilometer (km²)': 1000000.0,
      'Square centimeter (cm²)': 0.0001,
      'Square millimeter (mm²)': 0.000001,
      'Square mile (mi²)': 2589988.11,
      'Square yard (yd²)': 0.836127,
      'Square foot (ft²)': 0.092903,
      'Square inch (in²)': 0.00064516,
      'Acre': 4046.86,
      'Hectare (ha)': 10000.0,
    },
    'Temperature': {
      'Celsius (°C)': 1.0,
      'Fahrenheit (°F)': 1.8,
      'Kelvin (K)': 273.15,
    },
    'Speed': {
      'Kilometers per hour (km/h)': 1.0,
      'Miles per hour (mph)': 1.60934,
      'Meters per second (m/s)': 3.6,
      'Feet per second (ft/s)': 1.09728,
      'Knots (kn)': 1.852,
    },
    'Time': {
      'Second (s)': 1.0,
      'Minute (min)': 60.0,
      'Hour (h)': 3600.0,
      'Day': 86400.0,
      'Week': 604800.0,
      'Month': 2629744.0,
      'Year': 31556926.0,
    },
    'Energy': {
      'Joule (J)': 1.0,
      'Kilojoule (kJ)': 1000.0,
      'Calorie (cal)': 4.184,
      'Kilocalorie (kcal)': 4184.0,
      'British Thermal Unit (BTU)': 1055.06,
      'Watt-hour (Wh)': 3600.0,
      'Kilowatt-hour (kWh)': 3600000.0,
    },
    'Power': {
      'Watt (W)': 1.0,
      'Kilowatt (kW)': 1000.0,
      'Horsepower (hp)': 745.7,
      'Megawatt (MW)': 1000000.0,
    },
    'Pressure': {
      'Pascal (Pa)': 1.0,
      'Kilopascal (kPa)': 1000.0,
      'Bar': 100000.0,
      'Atmosphere (atm)': 101325.0,
      'Torr': 133.322,
      'Pound per square inch (psi)': 6894.76,
    },
    'Data': {
      'Byte (B)': 1.0,
      'Kilobyte (KB)': 1024.0,
      'Megabyte (MB)': 1048576.0,
      'Gigabyte (GB)': 1073741824.0,
      'Terabyte (TB)': 1099511627776.0,
      'Petabyte (PB)': 1125899906842624.0,
    },
    'Fuel Economy': {
      'Miles per gallon (mpg)': 1.0,
      'Kilometers per liter (km/L)': 2.35215,
      'Liters per 100 kilometers (L/100km)': 235.215,
    },
  };

  void _convert() {
    setState(() {
      if (_selectedCategory == 'Temperature') {
        _result = _convertTemperature(_fromUnit, _toUnit, _value);
      } else {
        final double conversionFactor =
            _units[_selectedCategory]![_toUnit]! / _units[_selectedCategory]![_fromUnit]!;
        _result = _value * conversionFactor;
      }
    });
  }

double _convertTemperature(String fromUnit, String toUnit, double value) {
  if (fromUnit == toUnit) {
    return value;
  } else if (fromUnit == 'Celsius (°C)' && toUnit == 'Fahrenheit (°F)') {
    return (value * 9 / 5) + 32;
  } else if (fromUnit == 'Celsius (°C)' && toUnit == 'Kelvin (K)') {
    return value + 273.15;
  } else if (fromUnit == 'Fahrenheit (°F)' && toUnit == 'Celsius (°C)') {
    return (value - 32) * 5 / 9;
  } else if (fromUnit == 'Fahrenheit (°F)' && toUnit == 'Kelvin (K)') {
    return ((value - 32) * 5 / 9) + 273.15;
  } else if (fromUnit == 'Kelvin (K)' && toUnit == 'Celsius (°C)') {
    return value - 273.15;
  } else if (fromUnit == 'Kelvin (K)' && toUnit == 'Fahrenheit (°F)') {
    return ((value - 273.15) * 9 / 5) + 32;
  } else {
    return 0.0; // Invalid conversion
  }
}


  void _onCategoryChanged(String value) {
    setState(() {
      _selectedCategory = value;
      _fromUnit = _units[_selectedCategory]!.keys.first;
      _toUnit = _units[_selectedCategory]!.keys.last;
    });
  }

  void _onFromUnitChanged(String? value) {
    if (value != null) {
      setState(() {
        _fromUnit = value;
      });
      _convert();
    }
  }

  void _onToUnitChanged(String? value) {
    if (value != null) {
      setState(() {
        _toUnit = value;
      });
      _convert();
    }
  }

void _onValueChanged(String? value) {
  if (value != null && double.tryParse(value) != null) {
    setState(() {
      _value = double.parse(value);
    });
    _convert();
  }
}

  // New method to swap the units
  void _swapUnits() {
    setState(() {
      String temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: Text(
    widget.title,
    style: TextStyle(
      fontWeight: FontWeight.bold, // This line makes the text bold
      // You can also adjust other style properties like fontSize, color, etc.
    ),
  ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
drawer: Drawer(
  child: ListView(
    children: [
      Container(
        padding: EdgeInsets.all(10.0), // Adjust padding as needed
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 62, 182, 139),
        ),
        child: Text(
          'Conversions',
          style: TextStyle(color: Colors.white, fontSize: 20), // Adjust font size as needed
        ),
        height: 60, // Set a fixed, smaller height for the header
      ),
            ListTile(
              title: Text('Length/Distance'),
              onTap: () {
                _onCategoryChanged('Length/Distance');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Mass/Weight'),
              onTap: () {
                _onCategoryChanged('Mass/Weight');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Volume'),
              onTap: () {
                _onCategoryChanged('Volume');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Area'),
              onTap: () {
                _onCategoryChanged('Area');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Temperature'),
              onTap: () {
                _onCategoryChanged('Temperature');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Speed'),
              onTap: () {
                _onCategoryChanged('Speed');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Time'),
              onTap: () {
                _onCategoryChanged('Time');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Energy'),
              onTap: () {
                _onCategoryChanged('Energy');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Power'),
              onTap: () {
                _onCategoryChanged('Power');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Pressure'),
              onTap: () {
                _onCategoryChanged('Pressure');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Data'),
              onTap: () {
                _onCategoryChanged('Data');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Fuel Economy'),
              onTap: () {
                _onCategoryChanged('Fuel Economy');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text(
              '$_selectedCategory Converter',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 20.0),

            // IconButton for swapping units
            IconButton(
              icon: Icon(Icons.swap_horiz),
              onPressed: _swapUnits,
              tooltip: 'Swap units',
            ),
            DropdownButton<String>(
              value: _toUnit, // Swap _fromUnit and _toUnit
              items: _units[_selectedCategory]!.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _onToUnitChanged, // Use _onToUnitChanged
            ),
            SizedBox(height: 20.0),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,6}'))],
              decoration: InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: _onValueChanged,
            ),
            SizedBox(height: 20.0),
            DropdownButton<String>(
              value: _fromUnit, // Swap _fromUnit and _toUnit
              items: _units[_selectedCategory]!.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _onFromUnitChanged, // Use _onFromUnitChanged
            ),
            SizedBox(height: 20.0),
            Text(
              'Result: ${NumberFormat.decimalPattern().format(_result)} $_fromUnit', // Display unit next to result
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
      ),
    );
  }
}

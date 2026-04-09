import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MaterialApp(
  home: WeatherDashboard(),
  debugShowCheckedModeBanner: false,
));

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  final String apiKey = "85aa0f67c59c79e703d32565b6befaa0";

  String cityName = "Sta. Ana, Pampanga";
  String temp = "--";
  String desc = "Loading...";
  String humidity = "--";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default starting point for the presentation
    _fetchWeather("Santa Ana, Pampanga, PH");
  }

  // --- STEP 1: PHILIPPINES-ONLY SUGGESTIONS ---
  Future<Iterable<String>> _getSuggestions(String query) async {
    if (query.length < 2) return const Iterable<String>.empty();

    // Adding ',PH' forces the search to stay within the Philippines
    final url = 'https://api.openweathermap.org/geo/1.0/direct?q=$query,PH&limit=8&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);

        // Final safety check to ensure we only show PH results
        return data.where((item) => item['country'] == 'PH').map((item) {
          String name = item['name'];
          String state = item['state'] ?? "Philippines";
          return "$name, $state";
        });
      }
    } catch (e) {
      return const Iterable<String>.empty();
    }
    return const Iterable<String>.empty();
  }

  // --- STEP 2: WEATHER FETCH LOGIC ---
  Future<void> _fetchWeather(String location) async {
    setState(() => isLoading = true);

    // Appending ',PH' here ensures the weather data is also from the Philippines
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$location,PH&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cityName = data['name'];
          temp = data['main']['temp'].toStringAsFixed(1);
          desc = data['weather'][0]['description'];
          humidity = data['main']['humidity'].toString();
          isLoading = false;
        });
      } else {
        _showError("Location not found in the Philippines.");
      }
    } catch (e) {
      _showError("Connection error.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  "PH WEATHER EXPLORER",
                  style: TextStyle(color: Colors.white60, letterSpacing: 3, fontSize: 12),
                ),
                const SizedBox(height: 15),

                // --- AUTOCOMPLETE SEARCH BAR ---
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return _getSuggestions(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _fetchWeather(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search PH City (e.g. Cebu, Baguio)",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                  children: [
                    const Icon(Icons.location_city, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      cityName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "$temp°C",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 90,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    Text(
                      desc.toUpperCase(),
                      style: const TextStyle(color: Colors.white60, letterSpacing: 5),
                    ),
                  ],
                ),

                const Spacer(),

                // DATA SUMMARY CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoItem("HUMIDITY", "$humidity%"),
                      _infoItem("REGION", "Philippines"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // REFRESH TO CURRENT SCHOOL LOCATION
                ElevatedButton.icon(
                  onPressed: () => _fetchWeather("Santa Ana, Pampanga, PH"),
                  icon: const Icon(Icons.refresh),
                  label: const Text("REFRESH SCHOOL LOCATION"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
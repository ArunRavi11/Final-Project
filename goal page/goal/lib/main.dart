import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Goal and Recommendation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LearningGoalAndRecommendationPage(),
    );
  }
}

class LearningGoalAndRecommendationPage extends StatefulWidget {
  const LearningGoalAndRecommendationPage({Key? key}) : super(key: key);

  @override
  _LearningGoalAndRecommendationPageState createState() =>
      _LearningGoalAndRecommendationPageState();
}

class _LearningGoalAndRecommendationPageState
    extends State<LearningGoalAndRecommendationPage> {
  final TextEditingController goalNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? beginDate;
  DateTime? endDate;
  bool isLoading = false;
  Map<String, dynamic>? recommendation;

  Future<void> submitForm() async {
    const String apiUrl = 'http://localhost:8080/goalpage/postgoals';
    final Map<String, String> requestData = {
      'goal_name': goalNameController.text,
      'description': descriptionController.text,
      'begin_date': beginDate!.toIso8601String(),
      'end_date': endDate!.toIso8601String()
    };

    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        // Handle successful submission
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Your goal submitted successfully! 😃'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        // Clear form fields
        goalNameController.clear();
        beginDate = null;
        endDate = null;
        descriptionController.clear();

        // Call AI server after successful submission
        await fetchRecommendation();
      } else {
        // Handle error response from the backend
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text(
                  'Failed to submit form. Please try again later.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      // Handle any exceptions (e.g., network errors)
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: $error'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> fetchRecommendation() async {
    setState(() {
      isLoading = true;
    });

    final apiUrl = Uri.parse('http://127.0.0.1:5000/recommendations');
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> requestBody = {
      "goalName": goalNameController.text,
      "description": descriptionController.text,
      "beginDate": beginDate!.toIso8601String(),
      "endDate": endDate!.toIso8601String()
    };

    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            // Assuming the first item is the book recommendation and the second is the event recommendation
            recommendation = {
              'Book': data[0],
              'Event': data[1]
            };
          });
        } else {
          // No recommendation found
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('No Recommendation'),
                content:
                    const Text('Sorry, we don\'t have any recommendations.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Handle error responses
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBeginDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null)
      setState(() {
        if (isBeginDate) {
          beginDate = picked;
        } else {
          endDate = picked;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning Goal and Recommendation'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: goalNameController,
                    decoration: InputDecoration(labelText: 'Goal Name'),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: beginDate != null
                                  ? beginDate!.toString().substring(0, 10)
                                  : ''),
                          decoration: InputDecoration(
                            labelText: 'Begin Date',
                          ),
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: endDate != null
                                  ? endDate!.toString().substring(0, 10)
                                  : ''),
                          decoration: InputDecoration(
                            labelText: 'End Date',
                          ),
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: submitForm,
                    child: Text('Submit Goal'),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(                    onPressed: fetchRecommendation,
                    child: Text('Get Recommendation'),
                  ),
                  SizedBox(height: 20.0),
                  if (recommendation != null) ...[
                    if (recommendation!.containsKey('Book')) ...[
                      Text('Recommended Book:'),
                      SizedBox(height: 10.0),
                      Text('Title: ${recommendation!['Book']['Title']}'),
                      Text('Author: ${recommendation!['Book']['Author']}'),
                      Text('Genre: ${recommendation!['Book']['Genre']}'),
                      Text('Ratings: ${recommendation!['Book']['Ratings']}'),
                      Text('Description: ${recommendation!['Book']['Description']}'),
                      SizedBox(height: 20.0),
                    ],
                    if (recommendation!.containsKey('Event')) ...[
                      Text('Recommended Event:'),
                      SizedBox(height: 10.0),
                      Text('Title: ${recommendation!['Event']['Title']}'),
                      Text('Speaker: ${recommendation!['Event']['Speaker']}'),
                      Text('Event Mode: ${recommendation!['Event']['Event Mode']}'),
                      Text('Date: ${recommendation!['Event']['Date']}'),
                      Text('Location: ${recommendation!['Event']['Location']}'),
                      Text('Description: ${recommendation!['Event']['Description']}'),
                      SizedBox(height: 20.0),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}


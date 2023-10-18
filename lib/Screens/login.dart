import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:vertretungsplan/units_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<Response>? loginStatus;

  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  Future<Response> login(String username, String password) async {
    Response loginStatus = await untisLogin(username, password);
    return loginStatus;
  }

  void saveLogin(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    await prefs.setString("password", password);
    if (context.mounted) Navigator.pushNamed(context, "/home");
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vertretungsplan LIO",
          style: Theme.of(context).primaryTextTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Login",
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: usernameController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'User Name',
                  hintText: 'Enter your Username'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Password',
                  hintText: 'Enter your password'),
            ),
          ),
          (loginStatus == null)
              ? const SizedBox.shrink()
              : FutureBuilder(
                  future: loginStatus,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.statusCode != 200) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text("Invalid username or password", style: Theme.of(context).textTheme.titleSmall!.copyWith(color:Theme.of(context).colorScheme.error),),
                        );
                      }
                      else{
                        saveLogin(usernameController.text, passwordController.text);
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            "Logged In",
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.tertiary),
                          ),
                        );
                      }
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text("Error: ${snapshot.data}"),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    loginStatus = login(usernameController.text, passwordController.text);
                  });
                },
                child: const Text("Login")),
          ),
          const Expanded(
            flex: 3,
            child: SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}

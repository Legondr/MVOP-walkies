import 'package:auto_route/auto_route.dart';
import 'package:walkies/components/custom_button.dart';
import 'package:walkies/components/custom_textfield.dart';
import 'package:walkies/components/square_tile.dart';
import 'package:walkies/screens/forgotPasswordScreen/forgot_password_screen.dart';
import 'package:walkies/services/authService/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

@RoutePage()
class RegisterScreen extends StatefulWidget {
  final Function()? onTap;
  const RegisterScreen({
    super.key,
    required this.onTap,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Sign up method
  void signUserUp() async {
    // Show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Check if passwords match
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      // Close the loading dialog before showing the error
      Navigator.pop(context);
      errorMessage("Passwords do not match.");
      return; // Stop further execution
    }

    // Try creating user
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Pop loading circle
      // Ensure widget is mounted before popping the loading circle
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Ensure widget is mounted before popping the loading circle
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error message
      errorMessage(e.code);
    }
  }

  // Error message to user
  void errorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DMCalendar',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 3, 192, 244),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Login text
                const SizedBox(height: 50),
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 45,
                  ),
                ),

                // Email text field
                const SizedBox(height: 50),
                CustomTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),

                // Password text field
                CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                // Confirmed assword text field
                CustomTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),

                // Forget password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const ForgotPasswordScreen();
                              },
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color.fromARGB(255, 100, 98, 98),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sign in button
                CustomButton(
                  textInButton: 'Sign up',
                  onTap: signUserUp,
                ),

                // Divider
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Color.fromARGB(255, 3, 192, 244),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            color: Color.fromARGB(255, 100, 98, 98),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Color.fromARGB(255, 3, 192, 244),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sign in via Apple or Google (Currently empty)
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //Placeholder for Google or Apple buttons
                    SquareTile(
                        onTap: () => AuthService().singInWithGoogle(),
                        imagePath: 'assets/images/googleLogo.png'),
                    const SizedBox(width: 10),
                    SquareTile(
                        onTap: () => AuthService().signInWithApple(),
                        imagePath: 'assets/images/appleLogo.png')
                  ],
                ),

                // Register text
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have account?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 100, 98, 98),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          color: Color.fromARGB(255, 3, 192, 244),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

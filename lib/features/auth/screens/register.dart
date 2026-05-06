import 'package:finance_app/features/auth/screens/login.dart';
import 'package:finance_app/features/auth/services/auth_services.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/navigation/CustomBottomBar.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final initialAmountController = TextEditingController();

  final auth = AuthService();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final userCred = await auth.register(
        email.text.trim(),
        password.text.trim(),
      );

      final uid = userCred.user?.uid;

      if (uid != null) {
        final amount =
            double.tryParse(initialAmountController.text.trim()) ?? 0.0;

        await UserFirestore(
          uid,
        ).userDoc.set({'balance': amount}, SetOptions(merge: true));
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomBottomBar()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Register failed: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Register",
                      style: TextStyle(fontSize: 28, color: Colors.white),
                    ),

                    const SizedBox(height: 20),

                    /// EMAIL
                    TextFormField(
                      controller: email,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains("@")) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    /// PASSWORD
                    TextFormField(
                      controller: password,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password is required";
                        }
                        if (value.length < 6) {
                          return "Minimum 6 characters required";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    /// CONFIRM PASSWORD
                    TextFormField(
                      controller: confirmPassword,
                      obscureText: obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != password.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    /// INITIAL AMOUNT
                    TextFormField(
                      controller: initialAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Initial Amount (Balance)",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter initial amount";
                        }
                        if (double.tryParse(value) == null) {
                          return "Enter a valid number";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : register,
                        child: loading
                            ? const CircularProgressIndicator()
                            : const Text(
                                "Register",
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// LOGIN NAV
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text("Login"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

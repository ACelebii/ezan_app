// lib/features/hatim/hatim_auth_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'hatim_provider.dart';

class HatimAuthPage extends StatelessWidget {
  const HatimAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text("Hesabım",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Giriş Kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildTextField(isDark, textColor, Icons.mail_outline_rounded,
                      "Mail Adresiniz"),
                  const SizedBox(height: 16),
                  _buildTextField(
                      isDark, textColor, Icons.password_rounded, "Şifre",
                      obscureText: true),
                  const SizedBox(height: 24),

                  // Giriş Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.white24 : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Simüle edilmiş giriş işlemi
                        context.read<HatimProvider>().isLoggedIn = true;
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Giriş Başarılı! Şimdi görevi alabilirsiniz."),
                              backgroundColor: Colors.teal),
                        );
                      },
                      child: Text("Giriş Yap",
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alt Linkler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Hesap Oluştur",
                          style: TextStyle(
                              color: subTextColor,
                              fontWeight: FontWeight.w500)),
                      Text("Şifremi Unuttum",
                          style: TextStyle(
                              color: subTextColor,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: Divider(color: subTextColor.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("veya",
                      style: TextStyle(color: subTextColor, fontSize: 12)),
                ),
                Expanded(child: Divider(color: subTextColor.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 30),

            // Apple ile Giriş
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.black : Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.apple, color: Colors.white),
                label: const Text("Apple ile Giriş Yap",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 16),

            // Google ile Giriş
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Image.network(
                    "https://img.icons8.com/color/48/000000/google-logo.png",
                    width: 24), // Google Icon
                label: const Text("Oturum aç",
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      bool isDark, Color textColor, IconData icon, String hint,
      {bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

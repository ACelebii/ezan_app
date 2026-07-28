import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  bool _validateReset(String email) {
    final authService = context.read<AuthService>();
    if (email.isEmpty) {
      _showError(authService.translate("Lütfen mail adresinizi yazın."));
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError(
          authService.translate("Lütfen geçerli bir e-posta adresi yazın."));
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    Color fieldBgColor =
        isDark(context) ? const Color(0xFF1C1C1E) : Colors.grey.shade100;
    Color fieldBorderColor = isDark(context) ? Colors.white10 : Colors.black12;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Şifre Sıfırlama"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: getBgColor(context),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      Colors.purple.shade400,
                      Colors.deepPurple.shade400
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ]),
                child: const Icon(Icons.lock_reset_rounded,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(authService.translate("Şifrenizi mi Unuttunuz?"),
                  style: TextStyle(
                      color: getTextColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  authService.translate(
                      "Hesabınıza bağlı e-posta adresini girin, size güvenli bir sıfırlama bağlantısı gönderelim."),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: getSubTextColor(context),
                      fontSize: 15,
                      height: 1.4)),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: getCardColor(context),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: getTextColor(context)),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          hintText:
                              authService.translate("Kayıtlı Mail Adresiniz"),
                          hintStyle: TextStyle(color: getSubTextColor(context)),
                          prefixIcon: Icon(Icons.mail_rounded,
                              color: getSubTextColor(context)),
                          filled: true,
                          fillColor: fieldBgColor,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: fieldBorderColor, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Colors.purple.shade400, width: 1.5)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18)),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [
                            Colors.purple.shade400,
                            Colors.deepPurple.shade400
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.purple.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: authService.isLoading
                            ? null
                            : () async {
                                String mail = _emailController.text.trim();
                                if (!_validateReset(mail)) return;
                                String? errorMessage =
                                    await authService.resetPassword(mail);
                                if (errorMessage != null && context.mounted) {
                                  _showError(errorMessage);
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(authService.translate(
                                              "Sıfırlama bağlantısı mailinize gönderildi!")),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating));
                                  context.pop();
                                }
                              },
                        child: authService.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(authService.translate("Bağlantı Gönder"),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


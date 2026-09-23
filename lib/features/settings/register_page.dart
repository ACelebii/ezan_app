import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  bool _validateRegister(String email, String password) {
    final authService = context.read<AuthService>();
    if (email.isEmpty || password.isEmpty) {
      _showError(authService
          .translate("Lütfen e-posta ve şifre alanlarını boş bırakmayın."));
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError(
          authService.translate("Lütfen geçerli bir e-posta adresi girin."));
      return false;
    }
    if (password.length < 8) {
      _showError(authService
          .translate("Güvenliğiniz için şifreniz en az 8 karakter olmalıdır."));
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          title: Text(authService.translate("Hesap Oluştur"),
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
                    gradient: LinearGradient(
                        colors: [Colors.cyan.shade400, Colors.blue.shade600]),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.cyan.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ]),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(authService.translate("Aramıza Katıl"),
                  style: TextStyle(
                      color: getTextColor(context),
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  authService.translate(
                      "Ayarlarını buluta kaydetmek ve her cihazdan erişmek için ücretsiz kayıt ol."),
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
                          hintText: authService.translate("Mail Adresiniz"),
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
                              borderSide: const BorderSide(
                                  color: Colors.cyan, width: 1.5)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: getTextColor(context)),
                      decoration: InputDecoration(
                          hintText: authService.translate("Şifre Belirleyin"),
                          hintStyle: TextStyle(color: getSubTextColor(context)),
                          prefixIcon: Icon(Icons.lock_rounded,
                              color: getSubTextColor(context)),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: getSubTextColor(context)),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible)),
                          filled: true,
                          fillColor: fieldBgColor,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: fieldBorderColor, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Colors.cyan, width: 1.5)),
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
                            Colors.cyan.shade400,
                            Colors.blue.shade600
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.cyan.withValues(alpha: 0.3),
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
                                String pass = _passwordController.text.trim();
                                if (!_validateRegister(mail, pass)) return;
                                String? errorMessage = await authService
                                    .registerWithEmail(mail, pass);
                                if (errorMessage != null && context.mounted) {
                                  _showError(errorMessage);
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(authService.translate(
                                              "Hesabınız oluşturuldu!")),
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
                            : Text(authService.translate("Kayıt Ol"),
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

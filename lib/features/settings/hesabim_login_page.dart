import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class HesabimLoginPage extends StatefulWidget {
  const HesabimLoginPage({super.key});
  @override
  State<HesabimLoginPage> createState() => _HesabimLoginPageState();
}

class _HesabimLoginPageState extends State<HesabimLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating));
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validateLogin(String email, String password) {
    final authService = context.read<AuthService>();
    if (email.isEmpty || password.isEmpty) {
      _showError(authService.translate("Lütfen e-posta ve şifrenizi girin."));
      return false;
    }
    if (!_isEmailValid(email)) {
      _showError(
          authService.translate("Lütfen geçerli bir e-posta adresi girin."));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isUserLoggedIn = authService.user != null;
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
          title: Text(
              authService.translate(isUserLoggedIn ? "Profilim" : "Hesabım"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isUserLoggedIn
              ? _buildLoggedInView(context, authService)
              : _buildLoginView(
                  context, authService, fieldBgColor, fieldBorderColor),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withValues(alpha: 0.1)),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent, size: 80)),
        const SizedBox(height: 24),
        Text(authService.translate("Hoş Geldin!"),
            textAlign: TextAlign.center,
            style: TextStyle(color: getSubTextColor(context), fontSize: 18)),
        const SizedBox(height: 10),
        Text(authService.user!.email!,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: getTextColor(context),
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        SizedBox(
            height: 55,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () async => await authService.logout(),
                child: Text(authService.translate("Çıkış Yap"),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)))),
      ],
    );
  }

  Widget _buildLoginView(BuildContext context, AuthService authService,
      Color fieldBgColor, Color fieldBorderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
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
                        borderSide:
                            BorderSide(color: fieldBorderColor, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: getAccentColor(context), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(color: getTextColor(context)),
                decoration: InputDecoration(
                    hintText: authService.translate("Şifre"),
                    hintStyle: TextStyle(color: getSubTextColor(context)),
                    prefixIcon: Icon(Icons.lock_rounded,
                        color: getSubTextColor(context)),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: getSubTextColor(context)),
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible)),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: fieldBorderColor, width: 1)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: getAccentColor(context), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        colors: isDark(context)
                            ? [Colors.yellow.shade600, Colors.orange.shade500]
                            : [
                                Colors.orange.shade400,
                                Colors.deepOrange.shade400
                              ]),
                    boxShadow: [
                      BoxShadow(
                          color: getAccentColor(context).withValues(alpha: 0.3),
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
                          if (!_validateLogin(mail, pass)) return;
                          String? errorMessage =
                              await authService.loginWithEmail(mail, pass);
                          if (errorMessage != null && context.mounted) {
                            _showError(errorMessage);
                          } else if (context.mounted) {
                            _showSuccess("Başarıyla giriş yapıldı!");
                            context.pop();
                          }
                        },
                  child: authService.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(authService.translate("Giriş Yap"),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                  onTap: () => context.push('/settings/hesabim/kayit'),
                  child: Text(authService.translate("Hesap Oluştur"),
                      style: TextStyle(
                          color: getAccentColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w600))),
              GestureDetector(
                  onTap: () =>
                      context.push('/settings/hesabim/sifremi-unuttum'),
                  child: Text(authService.translate("Şifremi Unuttum"),
                      style: TextStyle(
                          color: getSubTextColor(context), fontSize: 15))),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Row(children: [
          Expanded(child: Divider(color: getDividerColor(context))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(authService.translate("veya"),
                  style: TextStyle(
                      color: getSubTextColor(context), fontSize: 14))),
          Expanded(child: Divider(color: getDividerColor(context)))
        ]),
        const SizedBox(height: 30),
        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
          SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark(context) ? Colors.white : Colors.black,
                      foregroundColor:
                          isDark(context) ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  icon: Icon(Icons.apple,
                      size: 26,
                      color: isDark(context) ? Colors.black : Colors.white),
                  label: Text(authService.translate("Apple ile Giriş Yap"),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _showError(
                      "Apple ile giriş çok yakında aktif edilecek!"))),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark(context) ? const Color(0xFF2C2C2E) : Colors.white,
                foregroundColor: getTextColor(context),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: isDark(context) ? 0 : 2),
            icon: Image.network(
                "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata,
                    color: Colors.blue,
                    size: 28)),
            label: Text(authService.translate("Google ile Oturum Aç"),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: authService.isLoading
                ? null
                : () async {
                    String? errorMessage = await authService.signInWithGoogle();
                    if (errorMessage != null &&
                        errorMessage != "Google girişi iptal edildi." &&
                        context.mounted) {
                      _showError(errorMessage);
                    } else if (errorMessage == null && context.mounted) {
                      _showSuccess("Google ile başarıyla giriş yapıldı!");
                      context.pop();
                    }
                  },
          ),
        ),
      ],
    );
  }
}


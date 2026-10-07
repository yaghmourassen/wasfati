
import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';
import '../generated/l10n/app_localizations.dart';
import 'home_view.dart';

class AuthView extends StatefulWidget {
const AuthView({super.key});

@override
State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView>
with SingleTickerProviderStateMixin {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _nameController = TextEditingController();
final _controller = AuthController();

bool _isLoading = false;
bool _isLogin = true;
bool _obscurePassword = true;
String? _errorMessage;

late AnimationController _fadeController;
late Animation<double> _fadeAnimation;

@override
void initState() {
super.initState();

_fadeController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 800),
)..forward();

_fadeAnimation = CurvedAnimation(
parent: _fadeController,
curve: Curves.easeOutCubic,
);
}

@override
void dispose() {
_fadeController.dispose();
_emailController.dispose();
_passwordController.dispose();
_nameController.dispose();
super.dispose();
}

Future<void> _handleAuth() async {
if (!_formKey.currentState!.validate()) return;

setState(() {
_isLoading = true;
_errorMessage = null;
});

try {
if (_isLogin) {
final user = await _controller.login(
_emailController.text.trim(),
_passwordController.text.trim(),
);

if (user != null && mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const HomeView(),
),
);
}
} else {
final user = await _controller.register(
name: _nameController.text.trim(),
email: _emailController.text.trim(),
password: _passwordController.text.trim(),
);

if (user != null && mounted) {
final t = AppLocalizations.of(context)!;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(t.accountCreated),
behavior: SnackBarBehavior.floating,
margin: const EdgeInsets.all(16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
);

await _controller.logout();

setState(() {
_isLogin = true;
_emailController.clear();
_passwordController.clear();
_nameController.clear();
});
}
}
} catch (e) {
if (mounted) {
setState(() {
_errorMessage = e.toString();
});
}
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

void _toggleForm() {
setState(() {
_isLogin = !_isLogin;
_errorMessage = null;
_obscurePassword = true;
});
}

@override
Widget build(BuildContext context) {
final t = AppLocalizations.of(context)!;
final theme = Theme.of(context);
final primary = theme.colorScheme.primary;

return Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,
body: SafeArea(
child: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 28,
),
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 500,
),
child: FadeTransition(
opacity: _fadeAnimation,
child: Column(
children: [
// =====================================================
// BRAND HEADER
// =====================================================
Container(
width: 82,
height: 82,
decoration: BoxDecoration(
color: primary.withOpacity(0.10),
shape: BoxShape.circle,
),
child: Icon(
Icons.restaurant_rounded,
size: 42,
color: primary,
),
),

const SizedBox(height: 18),

Text(
t.appTitle,
textAlign: TextAlign.center,
style: theme.textTheme.headlineMedium?.copyWith(
color: primary,
fontWeight: FontWeight.w900,
letterSpacing: -0.5,
),
),

const SizedBox(height: 8),

AnimatedSwitcher(
duration: const Duration(milliseconds: 250),
child: Text(
_isLogin
? t.welcomeBack
    : t.createAccountMsg,
key: ValueKey(_isLogin),
textAlign: TextAlign.center,
style: theme.textTheme.bodyMedium?.copyWith(
color: theme.textTheme.bodyMedium?.color
    ?.withOpacity(0.65),
height: 1.4,
),
),
),

const SizedBox(height: 30),

// =====================================================
// AUTH CARD
// =====================================================
Container(
width: double.infinity,
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(26),
border: Border.all(
color: primary.withOpacity(0.08),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// =================================================
// FORM TITLE
// =================================================
Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: primary.withOpacity(0.10),
borderRadius: BorderRadius.circular(13),
),
child: Icon(
_isLogin
? Icons.login_rounded
    : Icons.person_add_alt_1_rounded,
color: primary,
size: 21,
),
),
const SizedBox(width: 12),
Expanded(
child: AnimatedSwitcher(
duration:
const Duration(milliseconds: 200),
child: Text(
_isLogin
? t.login
    : t.createAccount,
key: ValueKey(_isLogin),
style:
theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),
),
),
],
),

const SizedBox(height: 22),

// =================================================
// FULL NAME
// =================================================
AnimatedSize(
duration: const Duration(milliseconds: 250),
curve: Curves.easeOut,
child: _isLogin
? const SizedBox.shrink()
    : Column(
children: [
_field(
controller: _nameController,
hint: t.fullName,
icon: Icons.person_outline_rounded,
color: primary,
),
const SizedBox(height: 14),
],
),
),

// =================================================
// EMAIL
// =================================================
_field(
controller: _emailController,
hint: t.email,
icon: Icons.email_outlined,
color: primary,
keyboardType: TextInputType.emailAddress,
),

const SizedBox(height: 14),

// =================================================
// PASSWORD
// =================================================
_field(
controller: _passwordController,
hint: t.password,
icon: Icons.lock_outline_rounded,
color: primary,
obscure: _obscurePassword,
suffix: IconButton(
tooltip: _obscurePassword
? 'Show password'
    : 'Hide password',
icon: Icon(
_obscurePassword
? Icons.visibility_off_outlined
    : Icons.visibility_outlined,
color: primary.withOpacity(0.75),
size: 21,
),
onPressed: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
),
),

// =================================================
// ERROR
// =================================================
AnimatedSize(
duration: const Duration(milliseconds: 200),
child: _errorMessage == null
? const SizedBox.shrink()
    : Padding(
padding: const EdgeInsets.only(
top: 14,
),
child: Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 11,
),
decoration: BoxDecoration(
color: Colors.red.withOpacity(0.07),
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color:
Colors.red.withOpacity(0.15),
),
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Icon(
Icons.error_outline_rounded,
color: Colors.red,
size: 19,
),
const SizedBox(width: 9),
Expanded(
child: Text(
_errorMessage!,
style: const TextStyle(
color: Colors.red,
fontSize: 13,
height: 1.35,
),
),
),
],
),
),
),
),

const SizedBox(height: 20),

// =================================================
// MAIN BUTTON
// =================================================
SizedBox(
width: double.infinity,
height: 52,
child: ElevatedButton(
onPressed:
_isLoading ? null : _handleAuth,
style: ElevatedButton.styleFrom(
backgroundColor: primary,
foregroundColor: Colors.white,
disabledBackgroundColor:
primary.withOpacity(0.55),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
),
child: AnimatedSwitcher(
duration:
const Duration(milliseconds: 200),
child: _isLoading
? const SizedBox(
key: ValueKey('loading'),
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2.4,
color: Colors.white,
),
)
    : Row(
key: const ValueKey('button'),
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
_isLogin
? Icons.login_rounded
    : Icons.person_add_rounded,
size: 19,
),
const SizedBox(width: 9),
Text(
_isLogin
? t.login
    : t.createAccount,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
],
),
),
),
),

const SizedBox(height: 16),

// =================================================
// SWITCH AUTH MODE
// =================================================
Center(
child: TextButton(
onPressed: _isLoading ? null : _toggleForm,
style: TextButton.styleFrom(
foregroundColor: primary,
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
),
child: Text(
_isLogin
? t.newHere
    : t.alreadyHaveAccount,
textAlign: TextAlign.center,
style: TextStyle(
color: primary,
fontWeight: FontWeight.w700,
fontSize: 13.5,
),
),
),
),
],
),
),
),

const SizedBox(height: 24),

// =====================================================
// BOTTOM BRANDING
// =====================================================
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.restaurant_rounded,
size: 16,
color: primary.withOpacity(0.45),
),
const SizedBox(width: 7),
Text(
t.appTitle,
style: theme.textTheme.bodySmall?.copyWith(
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.45),
fontWeight: FontWeight.w600,
),
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

Widget _field({
required TextEditingController controller,
required String hint,
required IconData icon,
required Color color,
bool obscure = false,
Widget? suffix,
TextInputType? keyboardType,
}) {
final theme = Theme.of(context);
final t = AppLocalizations.of(context)!;

return TextFormField(
controller: controller,
obscureText: obscure,
keyboardType: keyboardType,
textInputAction: TextInputAction.next,
style: theme.textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
decoration: InputDecoration(
hintText: hint,
hintStyle: theme.textTheme.bodyMedium?.copyWith(
color: theme.textTheme.bodyMedium?.color?.withOpacity(0.45),
),
prefixIcon: Icon(
icon,
color: color.withOpacity(0.75),
size: 21,
),
suffixIcon: suffix,
filled: true,
fillColor: theme.scaffoldBackgroundColor.withOpacity(0.55),
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 16,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: BorderSide(
color: color.withOpacity(0.08),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: BorderSide(
color: color.withOpacity(0.65),
width: 1.4,
),
),
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: BorderSide(
color: Colors.red.withOpacity(0.45),
),
),
focusedErrorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: const BorderSide(
color: Colors.red,
width: 1.3,
),
),
),
validator: (v) {
if (v == null || v.trim().isEmpty) {
return t.requiredField;
}
return null;
},
);
}
}

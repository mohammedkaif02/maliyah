import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/finance/finance_bloc.dart';
import 'blocs/finance/finance_event.dart';
import 'blocs/theme/theme_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = const AppBlocObserver();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final storage = await StorageService.init();

  final authRepo = FirebaseAuthRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(storage)),

        BlocProvider<AuthCubit>(create: (_) => AuthCubit(authRepo)),

        BlocProvider<FinanceBloc>(
          create: (_) =>
              FinanceBloc(storage: storage)
                ..add(LoadFinanceDataEvent(userId: storage.currentUserId)),
        ),
      ],
      child: const MaliyahApp(),
    ),
  );
}

class MaliyahApp extends StatelessWidget {
  const MaliyahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: themeMode == ThemeMode.dark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: themeMode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
          ),
        );

        return MaterialApp(
          title: 'MĀLIYAH — Personal Finance',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}

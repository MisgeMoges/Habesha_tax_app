// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/repository/auth_repository_impl.dart';
import 'data/datasources/auth/auth.dart';
import 'core/network/network_info.dart';
import 'features/tax/bloc/tax_bloc.dart';
import 'features/tax/repository/tax_repository_impl.dart';
import 'data/datasources/tax/tax_remote_data_source.dart';

import 'features/general/home/home_screen.dart';
import 'features/general/splash_screen.dart';
import 'features/auth/views/auth_screen.dart';
import 'features/statistics/view/statistics_screen.dart';
import 'features/transaction/view/add_transaction_screen.dart';
import 'features/chat/view/chat_screen.dart';
import 'features/auth/views/profile_screen.dart';

// Import the BottomNavBar
import 'shared/navigations/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
      networkInfo: NetworkInfoImpl(InternetConnectionChecker()),
    );
    final taxRepository = TaxRepositoryImpl(
      remoteDataSource: TaxRemoteDataSourceImpl(),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc(authRepository)),
        BlocProvider(
          create: (context) => TaxBloc(
            taxRepository: taxRepository,
            authBloc: BlocProvider.of<AuthBloc>(context),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Habesha Tax App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
        home: const SplashScreen(),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    StatisticsScreen(),
    AddTransactionScreen(),
    AdminChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Unauthenticated) {
          return const AuthScreen();
        }

        if (state is Authenticated) {
          return Scaffold(
            body: _screens[_currentIndex],

            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: BottomNavBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          );
        }

        return const SplashScreen();
      },
    );
  }
}

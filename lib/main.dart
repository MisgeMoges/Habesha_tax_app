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
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

// Import the new screens
import 'features/statistics/view/statistics_screen.dart';
import 'features/transaction/view/add_transaction_screen.dart';
import 'features/chat/view/chat_screen.dart';
import 'features/auth/views/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        theme: ThemeData(
          primarySwatch: Colors.deepPurple, // Changed to match new UI
          useMaterial3: true,
        ),
        home: const AppWrapper(), // Changed from SplashScreen to AppWrapper
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
    HomeScreen(), // Your existing home screen
    StatisticsScreen(), // New statistics screen
    AddTransactionScreen(), // New add transaction screen
    AdminChatScreen(), // New chat screen
    ProfileScreen(), // New profile screen
  ];

  // @override
  // Widget build(BuildContext context) {
  //   return BlocBuilder<AuthBloc, AuthState>(
  //     builder: (context, state) {
  //       if (state is Unauthenticated) {
  //         return const SplashScreen(); // Or your login screen
  //       }

  //       if (state is Authenticated) {
  //         return Scaffold(
  //           body: Stack(
  //             children: [
  //               _screens[_currentIndex],

  //               // Floating button above bottom nav
  //             ],
  //           ),
  //           bottomNavigationBar: BottomNavigationBar(
  //             currentIndex: _currentIndex,
  //             onTap: (index) {
  //               setState(() {
  //                 _currentIndex = index;
  //               });
  //             },
  //             type: BottomNavigationBarType.fixed,
  //             items: [
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.home_outlined),
  //                 label: 'Home',
  //               ),
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.bar_chart_outlined),
  //                 label: 'Stats',
  //               ),

  //               // ✅ Replace this icon visually with the floating FAB
  //               BottomNavigationBarItem(
  //                 icon: GestureDetector(
  //                   child: Container(
  //                     width: 60,
  //                     height: 60,
  //                     decoration: BoxDecoration(
  //                       color: const Color(0xFF8A56E8),
  //                       shape: BoxShape.circle,
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.black26,
  //                           blurRadius: 10,
  //                           offset: Offset(0, 4),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Icon(Icons.add, color: Colors.white, size: 32),
  //                   ),
  //                 ),
  //                 label: '',
  //               ),

  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.chat_bubble_outline),
  //                 label: 'Chat',
  //               ),
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.person_outline),
  //                 label: 'Profile',
  //               ),
  //             ],
  //           ),
  //         );
  //       }

  //       return const SplashScreen();
  //     },
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

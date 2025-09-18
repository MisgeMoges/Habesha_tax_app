// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../announcements/bloc/announcement_bloc.dart';
// import '../../announcements/bloc/announcement_state.dart';

// class NotificationBadge extends StatelessWidget {
//   final Widget child;
//   final int? count;

//   const NotificationBadge({super.key, required this.child, this.count});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AnnouncementBloc, AnnouncementState>(
//       builder: (context, state) {
//         int notificationCount = 0;

//         if (state is AnnouncementsLoaded) {
//           // Count only unread announcements from the last 7 days
//           final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
//           notificationCount = state.announcements
//               .where(
//                 (announcement) =>
//                     announcement.timestamp.isAfter(sevenDaysAgo) &&
//                     !announcement.isRead,
//               )
//               .length;
//         }

//         return Stack(
//           children: [
//             child,
//             if (notificationCount > 0)
//               Positioned(
//                 right: 8,
//                 top: 5,
//                 child: Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   constraints: const BoxConstraints(
//                     minWidth: 16,
//                     minHeight: 16,
//                   ),
//                   child: Text(
//                     notificationCount > 99
//                         ? '99+'
//                         : notificationCount.toString(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }
